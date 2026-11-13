<?php
require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use App\Models\Order;
use App\Models\Product;
use App\Http\Resources\OrderResource;
use App\Http\Resources\ProductResource;

echo "=== 1) ORDERS RESOURCE TEST ===\n";
$userId = DB::table('orders')->value('user_id');
echo "testing user_id = $userId\n";
try {
    $orders = Order::where('user_id', $userId)->with(['items.product', 'address'])->latest()->paginate(50);
    $data = OrderResource::collection($orders)->response()->getData(true)['data'];
    echo "OK - orders count: " . count($data) . "\n";
    echo json_encode($data[0] ?? null, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n";
} catch (\Throwable $e) {
    echo "FAILED: " . get_class($e) . " => " . $e->getMessage() . "\n";
    echo $e->getFile() . ":" . $e->getLine() . "\n";
}

echo "\n=== 2) PRODUCT RESOURCE WITHOUT LOADED CATEGORY (as in order items) ===\n";
try {
    $p = Product::first();
    $out = (new ProductResource($p))->response()->getData(true);
    echo "OK\n" . json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n";
} catch (\Throwable $e) {
    echo "FAILED: " . get_class($e) . " => " . $e->getMessage() . "\n";
}

echo "\n=== 3) PRODUCT COLUMNS ===\n";
foreach (DB::select("PRAGMA table_info(products)") as $c) { echo "{$c->name} ({$c->type})\n"; }

echo "\n=== 4) ORDERS COLUMNS ===\n";
foreach (DB::select("PRAGMA table_info(orders)") as $c) { echo "{$c->name} ({$c->type})\n"; }

echo "\n=== 5) ADDRESSES COLUMNS ===\n";
foreach (DB::select("PRAGMA table_info(addresses)") as $c) { echo "{$c->name} ({$c->type})\n"; }
