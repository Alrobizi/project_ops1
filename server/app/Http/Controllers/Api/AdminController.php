<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BannerResource;
use App\Models\Campaign;
use App\Models\Discount;
use App\Models\Page;
use App\Models\AdminNotification;
use App\Models\Faq;
use App\Models\Setting;
use App\Models\User;
use App\Models\Order;
use App\Models\Product;
use App\Models\Banner;
use App\Services\FcmService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    // ============================================
    // لوحة التحكم - الإحصائيات
    // ============================================
    public function dashboard()
    {
        return response()->json([
            'data' => [
                'total_orders' => Order::count(),
                'total_customers' => User::count(),
                'total_products' => Product::count(),
                'total_sales' => Order::where('status', '!=', 'cancelled')->sum('total'),
                'active_customers' => User::whereHas('orders')->count(),
                'new_customers' => User::where('created_at', '>=', now()->startOfMonth())->count(),
            ]
        ]);
    }

    public function orders(Request $request)
    {
        $query = Order::with(['user', 'items.product', 'address'])->latest();
        if ($request->has('status') && $request->status !== 'all' && $request->status !== '') {
            $query->where('status', $request->status);
        }
        return response()->json([
            'success' => true,
            'data' => $query->paginate(25)
        ]);
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        $validated = $request->validate([
            'status' => 'required|string|in:pending,processing,shipped,delivered,cancelled'
        ]);
        $order->update(['status' => $validated['status']]);
        return response()->json([
            'success' => true,
            'message' => 'تم تحديث حالة الطلب بنجاح',
            'data' => $order
        ]);
    }

    // ============================================
    // الحملات التسويقية
    // ============================================
    public function campaigns()
    {
        return response()->json([
            'data' => Campaign::orderBy('created_at', 'desc')->get()
        ]);
    }

    public function storeCampaign(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string',
            'type' => 'required|string',
            'budget' => 'nullable|numeric',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
        ]);

        $campaign = Campaign::create($validated);
        return response()->json(['data' => $campaign], 201);
    }

    public function destroyCampaign($id)
    {
        Campaign::findOrFail($id)->delete();
        return response()->json(['message' => 'تم الحذف بنجاح']);
    }

    // ============================================
    // الخصومات
    // ============================================
    public function discounts()
    {
        return response()->json([
            'data' => Discount::orderBy('created_at', 'desc')->get()
        ]);
    }

    public function storeDiscount(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|unique:discounts,code',
            'type' => 'required|string',
            'value' => 'required|numeric',
            'min_order' => 'nullable|numeric',
            'max_usage' => 'nullable|integer',
            'status' => 'nullable|string',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
        ]);

        $discount = Discount::create($validated);
        return response()->json(['data' => $discount], 201);
    }

    public function destroyDiscount($id)
    {
        Discount::findOrFail($id)->delete();
        return response()->json(['message' => 'تم الحذف بنجاح']);
    }

    public function toggleDiscount($id)
    {
        $discount = Discount::findOrFail($id);
        $discount->update([
            'status' => $discount->status === 'active' ? 'expired' : 'active'
        ]);
        return response()->json(['data' => $discount]);
    }

    // ============================================
    // الصفحات
    // ============================================
    public function pages()
    {
        return response()->json([
            'data' => Page::orderBy('created_at', 'desc')->get()
        ]);
    }

    public function storePage(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string',
            'slug' => 'required|string|unique:pages,slug',
            'content' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $page = Page::create($validated);
        return response()->json(['data' => $page], 201);
    }

    public function destroyPage($id)
    {
        Page::findOrFail($id)->delete();
        return response()->json(['message' => 'تم الحذف بنجاح']);
    }

    // ============================================
    // الإشعارات
    // ============================================
    public function notifications()
    {
        return response()->json([
            'data' => AdminNotification::orderBy('created_at', 'desc')->get()
        ]);
    }

    public function storeNotification(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string',
            'body' => 'nullable|string',
            'type' => 'nullable|string',
            'user_id' => 'nullable|integer|exists:users,id',
        ]);

        $notification = AdminNotification::create($validated);

        $data = ['type' => $validated['type'] ?? 'general'];

        // إذا حُدد مستخدم معين يُرسل له فقط، وإلا يُرسل لجميع المستخدمين
        if (!empty($validated['user_id'])) {
            $user = User::find($validated['user_id']);
            $sentCount = FcmService::sendToUser(
                $user,
                $validated['title'],
                $validated['body'] ?? '',
                $data
            ) ? 1 : 0;
        } else {
            $sentCount = FcmService::sendToAllUsers(
                $validated['title'],
                $validated['body'] ?? '',
                $data
            );
        }

        return response()->json([
            'data' => $notification,
            'fcm_sent_count' => $sentCount,
            'target' => !empty($validated['user_id']) ? 'user' : 'all',
        ], 201);
    }

    public function destroyNotification($id)
    {
        AdminNotification::findOrFail($id)->delete();
        return response()->json(['message' => 'تم الحذف بنجاح']);
    }

    // ============================================
    // الأسئلة الشائعة
    // ============================================
    public function faqs()
    {
        return response()->json([
            'data' => Faq::where('is_active', true)->orderBy('sort_order')->get()
        ]);
    }

    public function storeFaq(Request $request)
    {
        $validated = $request->validate([
            'question' => 'required|string',
            'answer' => 'nullable|string',
            'sort_order' => 'nullable|integer',
        ]);

        $faq = Faq::create($validated);
        return response()->json(['data' => $faq], 201);
    }

    public function destroyFaq($id)
    {
        Faq::findOrFail($id)->delete();
        return response()->json(['message' => 'تم الحذف بنجاح']);
    }

    // ============================================
    // الإعدادات
    // ============================================
    public function publicSettings()
    {
        $whatsappNumber = Setting::get('whatsapp_number')
            ?: Setting::get('whatsapp_transfer_number')
            ?: Setting::get('store_phone');

        return response()->json([
            'data' => [
                'whatsapp_number' => $whatsappNumber,
                'store_phone' => Setting::get('store_phone'),
                'store_name' => Setting::get('store_name'),
                'store_email' => Setting::get('store_email'),
                'store_currency' => Setting::get('store_currency', 'YER'),
                'transfer_recipient_name' => Setting::get('transfer_recipient_name', 'صبري العبد ناصر الربيزي'),
            ],
        ]);
    }

    public function settings()
    {
        $settings = Setting::all()->groupBy('group');
        return response()->json(['data' => $settings]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'settings' => 'required|array',
            'settings.*.key' => 'required|string',
            'settings.*.value' => 'nullable|string',
        ]);

        foreach ($validated['settings'] as $item) {
            Setting::set($item['key'], $item['value'] ?? '');
        }

        return response()->json(['message' => 'تم تحديث الإعدادات بنجاح']);
    }

    // ============================================
    // البانرات
    // ============================================
    public function banners()
    {
        $banners = Banner::orderBy('created_at', 'desc')->get();

        return response()->json([
            'data' => BannerResource::collection($banners)->resolve(),
        ]);
    }

    public function storeBanner(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'image' => 'nullable|string',
            'link' => 'nullable|string|max:255',
            'sort_order' => 'nullable|integer',
            'is_active' => 'boolean',
        ]);

        $banner = Banner::create([
            'title' => $validated['title'],
            'image' => $validated['image'] ?? null,
            'link' => $validated['link'] ?? null,
            'sort_order' => $validated['sort_order'] ?? 0,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json(['data' => new BannerResource($banner)], 201);
    }

    public function destroyBanner($id)
    {
        Banner::findOrFail($id)->delete();
        return response()->json(['message' => 'تم الحذف بنجاح']);
    }

    public function toggleBanner($id)
    {
        $banner = Banner::findOrFail($id);
        $banner->update(['is_active' => !$banner->is_active]);
        return response()->json(['data' => $banner]);
    }

    // ============================================
    // العملاء
    // ============================================
    public function customers()
    {
        $customers = User::withCount('orders')
            ->withSum('orders', 'total')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'register_date' => $user->created_at->toDateString(),
                    'orders_count' => $user->orders_count,
                    'total_spent' => $user->orders_sum_total ?? 0,
                    'is_active' => true,
                    'is_vip' => ($user->orders_sum_total ?? 0) > 5000,
                    'is_new' => $user->created_at->gt(now()->subDays(30)),
                ];
            });

        return response()->json(['data' => $customers]);
    }

    public function toggleCustomerStatus($id)
    {
        $user = User::findOrFail($id);
        // يمكن إضافة حقل is_active لجدول المستخدمين
        return response()->json(['message' => 'تم تحديث حالة العميل']);
    }

    // ============================================
    // التقارير
    // ============================================
    public function reports()
    {
        $totalSales = Order::where('status', '!=', 'cancelled')->sum('total');
        $totalOrders = Order::count();
        $totalCustomers = User::count();
        $totalProducts = Product::count();

        // المبيعات الشهرية
        $monthlySales = Order::select(
                DB::raw('MONTH(created_at) as month'),
                DB::raw('SUM(total) as total')
            )
            ->whereYear('created_at', now()->year)
            ->where('status', '!=', 'cancelled')
            ->groupBy('month')
            ->get();

        // المنتجات الأكثر مبيعاً
        $topProducts = DB::table('order_items')
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->select(
                'products.name',
                DB::raw('SUM(order_items.quantity) as units_sold'),
                DB::raw('SUM(order_items.total_price) as revenue'),
                'products.stock'
            )
            ->groupBy('products.id', 'products.name', 'products.stock')
            ->orderByDesc('units_sold')
            ->limit(5)
            ->get();

        // المنتجات منخفضة المخزون
        $lowStockProducts = Product::where('stock', '<', 10)
            ->select('name', 'stock', 'price')
            ->get()
            ->map(function ($product) {
                return [
                    'name' => $product->name,
                    'stock' => $product->stock,
                    'revenue' => 0,
                    'units_sold' => 0,
                ];
            });

        return response()->json([
            'data' => [
                'total_sales' => $totalSales,
                'total_orders' => $totalOrders,
                'total_customers' => $totalCustomers,
                'total_products' => $totalProducts,
                'monthly_sales' => $monthlySales,
                'top_products' => $topProducts,
                'low_stock_products' => $lowStockProducts,
            ]
        ]);
    }
}