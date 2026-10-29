<x-filament-widgets::widget>
    <x-filament::section>
        <x-slot name="heading">
            <div class="flex items-center justify-between w-full">
                <div class="flex items-center gap-2">
                    <span class="text-base font-bold text-gray-950 dark:text-white">
                        المنتجات الأكثر مبيعاً
                    </span>
                </div>
                <a href="{{ \App\Filament\Resources\ProductResource::getUrl('index') }}" class="text-xs font-bold text-primary-600 hover:text-primary-700 dark:text-primary-400">
                    عرض الكل &larr;
                </a>
            </div>
        </x-slot>

        <x-slot name="description">
            أفضل الأصناف أداءً وإقبالاً في متجر بركة عدن
        </x-slot>

        <div class="space-y-4 pt-2">
            @forelse($this->topProducts as $product)
                <div class="flex items-center gap-3.5 p-3 rounded-2xl bg-gray-50/70 dark:bg-white/5 border border-gray-100 dark:border-white/10 hover:border-primary-500/30 transition-all duration-200">
                    @if(!empty($product->image))
                        <img src="{{ $product->image }}" alt="{{ $product->name }}" class="w-12 h-12 rounded-xl object-cover shadow-sm flex-shrink-0" />
                    @else
                        <div class="w-12 h-12 rounded-xl bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400 flex items-center justify-center font-bold text-xs flex-shrink-0">
                            {{ mb_substr($product->name, 0, 2) }}
                        </div>
                    @endif

                    <div class="flex-1 min-w-0">
                        <div class="flex items-center justify-between gap-2">
                            <h4 class="text-xs font-bold text-gray-900 dark:text-white truncate">
                                {{ $product->name }}
                            </h4>
                            <span class="text-xs font-bold font-mono text-gray-900 dark:text-gray-100 flex-shrink-0">
                                {{ number_format($product->total_revenue ?? 0, 2) }} ر.س
                            </span>
                        </div>

                        <div class="flex items-center justify-between text-[11px] text-gray-500 dark:text-gray-400 mt-1">
                            <span class="inline-flex items-center px-2 py-0.5 rounded-md bg-gray-200/60 dark:bg-white/10 text-gray-700 dark:text-gray-300 text-[10px]">
                                {{ $product->category_name ?? 'عام' }}
                            </span>
                            <span class="font-mono font-medium">
                                {{ $product->sales_count ?? 0 }} مبيعات
                            </span>
                        </div>

                        <div class="w-full bg-gray-200 dark:bg-gray-700 h-1.5 rounded-full overflow-hidden mt-2">
                            <div class="bg-primary-600 h-full rounded-full transition-all duration-500" style="width: {{ $product->percent ?? 50 }}%"></div>
                        </div>
                    </div>
                </div>
            @empty
                <div class="text-center py-6 text-gray-400 text-xs">
                    لا توجد منتجات مسجلة حتى الآن
                </div>
            @endforelse
        </div>
    </x-filament::section>
</x-filament-widgets::widget>
