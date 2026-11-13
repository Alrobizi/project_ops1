<?php

require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\NotificationLog;
use App\Models\Order;
use App\Models\User;
use App\Notifications\OrderCreatedNotification;
use App\Services\FcmService;
use Illuminate\Support\Facades\Schema;

echo "=== 1) SCHEMA ===\n";
echo 'notifications_log table: ' . (Schema::hasTable('notifications_log') ? 'YES' : 'NO') . "\n";
echo 'users.fcm_token column: ' . (Schema::hasColumn('users', 'fcm_token') ? 'YES' : 'NO') . "\n";

echo "\n=== 2) FCM ACCESS TOKEN ===\n";
$token = FcmService::getAccessToken();
if ($token) {
    echo 'OK - access token length: ' . strlen($token) . "\n";
    echo 'prefix: ' . substr($token, 0, 16) . "...\n";
} else {
    echo "NULL - credentials missing or invalid (push will never be delivered)\n";
}

echo "\n=== 3) NOTIFICATION -> CHANNEL -> LOG (direct notify) ===\n";
$user = User::orderBy('id')->first();
$order = Order::where('user_id', $user->id)->first() ?? Order::first();
echo "user_id={$user->id} order_id={$order->id}\n";

$originalToken = $user->fcm_token;
$before = NotificationLog::count();
$lastId = (int) (NotificationLog::max('id') ?? 0);

$user->fcm_token = 'TEST_INVALID_TOKEN_FOR_DIAG';
$user->saveQuietly();

try {
    $user->notify(new OrderCreatedNotification($order));
    echo "notify(): returned without throwing\n";
} catch (\Throwable $e) {
    echo 'THREW ' . get_class($e) . ': ' . $e->getMessage() . "\n";
    echo 'at ' . $e->getFile() . ':' . $e->getLine() . "\n";
}

$after = NotificationLog::count();
echo "notification_log rows: before={$before} after={$after} delta=" . ($after - $before) . "\n";

$row = NotificationLog::where('id', '>', $lastId)->latest('id')->first();
if ($row) {
    echo "new row: id={$row->id} type={$row->type}\n";
    echo 'title=' . $row->title . "\n";
    echo 'body=' . $row->body . "\n";
    echo 'data=' . json_encode($row->data, JSON_UNESCAPED_UNICODE) . "\n";
    echo 'created_at=' . $row->created_at . ' read_at=' . var_export($row->read_at, true) . "\n";
    echo 'JSON payload => ' . $row->toJson(JSON_UNESCAPED_UNICODE) . "\n";
} else {
    echo "NO new row was created -> the log pipeline is broken\n";
}

echo "\n=== 4) CLEANUP ===\n";
$deleted = NotificationLog::where('id', '>', $lastId)->delete();
$user->fcm_token = $originalToken;
$user->saveQuietly();
echo "deleted test rows: {$deleted}; fcm_token restored to: "
    . var_export(User::find($user->id)->fcm_token, true) . "\n";
