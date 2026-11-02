<?php

namespace App\Http\Controllers\Api;

use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends BaseApiController
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'phone' => ['required', 'string', 'max:20'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'],
            'role' => 'customer',
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('flutter-app')->plainTextToken;

        return $this->success([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'تم إنشاء الحساب بنجاح', 201);
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['بيانات الدخول غير صحيحة'],
            ]);
        }

        if ($user->is_blocked) {
            return $this->error('حسابك محظور، تواصل مع إدارة المتجر', 403);
        }

        $user->tokens()->delete();
        $token = $user->createToken('flutter-app')->plainTextToken;

        return $this->success([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'تم تسجيل الدخول بنجاح');
    }

    /**
     * تسجيل الدخول بواسطة Google.
     *
     * لا يثق الخادم بأي بيانات هوية قادمة من التطبيق (البريد/الاسم/المعرّف)،
     * بل يتحقق منها مباشرة مع Google عبر id_token أو access_token،
     * ثم ينشئ توكن Sanctum اعتماداً على البيانات الموثّقة فقط.
     */
    public function googleLogin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id_token' => ['nullable', 'string', 'max:8192'],
            'access_token' => ['nullable', 'string', 'max:4096'],
        ]);

        $idToken = $validated['id_token'] ?? null;
        $accessToken = $validated['access_token'] ?? null;

        if (blank($idToken) && blank($accessToken)) {
            return $this->error(
                'بيانات التحقق من Google مفقودة، حدّث التطبيق ثم أعد المحاولة',
                422
            );
        }

        $profile = $this->verifyGoogleCredential($idToken, $accessToken);

        if ($profile === null) {
            return $this->error('تعذر التحقق من حساب Google، أعد المحاولة لاحقاً', 401);
        }

        $user = User::where('google_id', $profile['sub'])
            ->orWhere('email', $profile['email'])
            ->first();

        if ($user) {
            if ($user->is_blocked) {
                return $this->error('حسابك محظور، تواصل مع إدارة المتجر', 403);
            }

            $user->update([
                'google_id' => $profile['sub'],
                'avatar' => $profile['picture'] ?? $user->avatar,
            ]);

            if ($user->email_verified_at === null) {
                $user->forceFill(['email_verified_at' => now()])->save();
            }
        } else {
            $user = User::create([
                'name' => $profile['name'],
                'email' => $profile['email'],
                'google_id' => $profile['sub'],
                'avatar' => $profile['picture'],
                'phone' => '',
                'role' => 'customer',
                'password' => Hash::make(bin2hex(random_bytes(16))),
            ]);

            $user->forceFill(['email_verified_at' => now()])->save();
        }

        $user->tokens()->delete();
        $token = $user->createToken('flutter-app')->plainTextToken;

        return $this->success([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'تم تسجيل الدخول بواسطة Google بنجاح');
    }

    /**
     * التحقق من هوية مستخدم Google عبر نقاط النهاية الرسمية لخدمة TokenInfo.
     *
     * يتم إرسال التوكن إلى Google فقط، ولا يُسجَّل أي توكن في سجلات التطبيق.
     *
     * @return array{sub: string, email: string, name: string, picture: string|null}|null
     */
    private function verifyGoogleCredential(?string $idToken, ?string $accessToken): ?array
    {
        // معرّف Google (ID Token) هو الأفضل لأنه يحتوي على الحقول الموثّقة مباشرة،
        // أما الويب فيُعيد access_token لذلك نتحقق منه بنقطة نهاية tokeninfo الخاصة به.
        $useIdToken = filled($idToken);

        $endpoint = $useIdToken
            ? 'https://oauth2.googleapis.com/tokeninfo'
            : 'https://www.googleapis.com/oauth2/v3/tokeninfo';

        $query = $useIdToken
            ? ['id_token' => (string) $idToken]
            : ['access_token' => (string) $accessToken];

        try {
            $response = Http::timeout(10)
                ->acceptJson()
                ->get($endpoint, $query);
        } catch (ConnectionException $e) {
            Log::warning('Google token verification failed: تعذر الاتصال بخدمة Google');

            return null;
        }

        if (! $response->successful()) {
            Log::warning('Google token verification failed: استجابة غير ناجحة', [
                'status' => $response->status(),
            ]);

            return null;
        }

        $payload = $response->json();

        if (! is_array($payload)) {
            Log::warning('Google token verification failed: استجابة فارغة');

            return null;
        }

        // التأكد من أن التوكن صادر لتطبيقنا (يمنع استخدام توكن تطبيق آخر).
        // نقطة نهاية الـ id_token تعيد aud، ونقطة نهاية الـ access token قد تعيد
        // issued_to أو audience، لذلك نفحص كل الحقول المكافئة.
        $audienceCandidates = array_values(array_filter(array_map(
            static fn ($value) => is_string($value) ? $value : '',
            [
                $payload['aud'] ?? '',
                $payload['audience'] ?? '',
                $payload['issued_to'] ?? '',
            ]
        )));

        $allowedAudiences = (array) config('services.google.allowed_client_ids', []);

        if (empty($audienceCandidates) || ! array_intersect($audienceCandidates, $allowedAudiences)) {
            Log::warning('Google token verification failed: معرّف العميل غير مطابق', [
                'audience' => $audienceCandidates,
            ]);

            return null;
        }

        $email = $payload['email'] ?? null;

        // الـ id_token يعيد sub، أما tokeninfo الخاص بالـ access token فيعتمد
        // تاريخياً على user_id، وكلاهما يمثل معرّف حساب Google نفسه.
        $subject = $payload['sub'] ?? $payload['user_id'] ?? null;

        $emailVerified = filter_var(
            $payload['email_verified'] ?? $payload['verified_email'] ?? false,
            FILTER_VALIDATE_BOOLEAN
        );

        if (blank($email) || blank($subject) || ! $emailVerified) {
            Log::warning('Google token verification failed: بريد غير موثّق');

            return null;
        }

        return [
            'sub' => (string) $subject,
            'email' => (string) $email,
            'name' => (string) ($payload['name'] ?? Str::before((string) $email, '@')),
            'picture' => isset($payload['picture']) ? (string) $payload['picture'] : null,
        ];
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->success(null, 'تم تسجيل الخروج بنجاح');
    }
}
