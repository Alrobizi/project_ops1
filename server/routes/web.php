<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect('/app/');
});

Route::get('/app/{any?}', function () {
    $indexPath = public_path('app/index.html');
    if (file_exists($indexPath)) {
        return response()->file($indexPath, [
            'Cache-Control' => 'no-cache, no-store, must-revalidate',
        ]);
    }
    return view('welcome');
})->where('any', '.*');

Route::get('/admin', function () {
    return response()->file(resource_path('views/admin.html'), [
        'Cache-Control' => 'no-cache, no-store, must-revalidate',
        'Pragma' => 'no-cache',
        'Expires' => '0',
    ]);
});
