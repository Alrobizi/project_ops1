<x-filament-panels::page>
<style>
.kpi-card{background:linear-gradient(135deg,var(--tint,#FFFFFF) 0%,#FFFFFF 62%);border-radius:20px;border:1px solid var(--bc,#E8EBF4);padding:1.25rem 1.35rem;box-shadow:0 2px 12px -2px rgba(109,93,246,.07),0 1px 4px -1px rgba(0,0,0,.04);transition:box-shadow .2s,transform .2s;position:relative;overflow:hidden}
.kpi-card:hover{box-shadow:0 8px 28px -4px var(--hc,rgba(109,93,246,.14));transform:translateY(-2px)}
.kpi-card::before{content:'';position:absolute;top:0;right:0;width:4px;height:100%;background:linear-gradient(180deg,var(--ac,#6D5DF6),rgba(109,93,246,.25));border-radius:0 2px 2px 0}
.kpi-card::after{content:'';position:absolute;bottom:-38px;left:-38px;width:96px;height:96px;border-radius:50%;background:var(--ac,#6D5DF6);opacity:.07;pointer-events:none}
.kpi-value{font-size:1.65rem;font-weight:800;letter-spacing:-.02em;color:var(--vc,#1E293B);line-height:1.15}
.kpi-label{font-size:.68rem;font-weight:700;text-transform:uppercase;letter-spacing:.07em;color:#94A3B8;margin-bottom:.3rem}
.kpi-top{display:flex;align-items:center;justify-content:space-between;gap:.4rem;margin-bottom:.7rem}
.kpi-unit{font-size:.6rem;font-weight:700;color:#94A3B8;margin-inline-start:.4rem}
.kpi-badge{display:inline-flex;align-items:center;gap:.25rem;font-size:.64rem;font-weight:700;padding:.18rem .55rem;border-radius:99px;border:1px solid transparent;white-space:nowrap}
.b-green{color:#059669;background:#ECFDF5;border-color:#D1FAE5}
.b-red{color:#E11D48;background:#FFF1F2;border-color:#FFE4E6}
.b-blue{color:#2563EB;background:#EFF6FF;border-color:#DBEAFE}
.b-amber{color:#D97706;background:#FFFBEB;border-color:#FDE68A}
.kpi-ic{width:2rem;height:2rem;border-radius:.75rem;display:flex;align-items:center;justify-content:center;flex-shrink:0;color:#fff;box-shadow:0 3px 10px -2px rgba(0,0,0,.25)}
.kpi-bottom{margin-top:1.05rem;padding-top:.75rem;border-top:1px solid #F1F5F9;display:flex;align-items:center;justify-content:space-between;font-size:.66rem;color:#94A3B8;font-weight:600}
.dash-card{background:#fff;border-radius:18px;border:1px solid #E8EBF4;box-shadow:0 2px 12px -2px rgba(109,93,246,.07);overflow:hidden;transition:box-shadow .2s;position:relative}
.dash-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,var(--tc1,#6D5DF6),var(--tc2,#8B5CF6));opacity:.9}
.dash-card:hover{box-shadow:0 8px 24px -4px rgba(109,93,246,.12)}
.dch{display:flex;align-items:center;justify-content:space-between;padding:.85rem 1.2rem;border-bottom:1px solid #F1F5F9}
.dch-l{display:flex;align-items:center;gap:.65rem}
.hic{width:34px;height:34px;border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0;color:#fff;box-shadow:0 3px 10px -2px var(--hs,rgba(109,93,246,.45))}
.dct{font-size:.93rem;font-weight:700;color:#1E293B}.dcs{font-size:.7rem;color:#94A3B8;margin-top:.12rem}
.dcb{padding:1rem 1.2rem}
.sdt{display:inline-flex;align-items:center;gap:.4rem;font-size:.7rem;font-weight:700;padding:.2rem .6rem;border-radius:7px}
.sdt .dot{width:7px;height:7px;border-radius:50%;flex-shrink:0}
.st-p{background:#FEF3C7;color:#92400E}.st-r{background:#FFEDD5;color:#C2410C}.st-s{background:#DBEAFE;color:#1E40AF}.st-d{background:#DCFCE7;color:#166534}.st-c{background:#FEE2E2;color:#991B1B}
.pbr{background:#EEF0FD;height:5px;border-radius:99px;overflow:hidden}
.pbf{height:100%;border-radius:99px;transition:width .6s ease}
.av{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,#6D5DF6,#9F8FF8);color:#fff;font-weight:800;font-size:.75rem;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.ptab{padding:.28rem .65rem;border-radius:8px;font-size:.7rem;font-weight:600;border:none;cursor:pointer;transition:all .15s;color:#64748B;background:transparent}
.ptab.active{background:linear-gradient(135deg,#6D5DF6,#5A47E5);color:#fff;box-shadow:0 2px 8px rgba(109,93,246,.3)}
.ptab:not(.active):hover{background:#EEF0FD;color:#6D5DF6}
.mcard{background:linear-gradient(135deg,#6D5DF6 0%,#5A47E5 45%,#4338CA 100%);border-radius:18px;padding:1.3rem;color:#fff;position:relative;overflow:hidden}
.mcard::before{content:'';position:absolute;top:-25px;left:-25px;width:110px;height:110px;border-radius:50%;background:rgba(255,255,255,.09)}
.mcard::after{content:'';position:absolute;bottom:-45px;right:-30px;width:130px;height:130px;border-radius:50%;background:rgba(255,255,255,.06)}
.mcard a{transition:transform .15s,box-shadow .15s}
.mcard a:hover{transform:translateY(-1px);box-shadow:0 5px 14px rgba(0,0,0,.25)}
.ot tr:hover td{background:#F8F7FF}
.ot td,.ot th{vertical-align:middle}
.dl-item{display:flex;align-items:center;justify-content:space-between;padding:.35rem .5rem;border-radius:9px;font-size:.73rem;transition:background .15s}
.dl-item:hover{background:#F8FAFC}
.fsel{background:#F6F7FB;border:1px solid #E8EBF4;color:#334155;font-weight:600;font-size:.72rem;padding:.45rem .8rem;border-radius:12px;outline:none;cursor:pointer;font-family:inherit}
.fsel:focus{border-color:#6D5DF6}
.dark .fsel{background:#0B0F19;border-color:#1F293D;color:#CBD5E1}
@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
.kpi-card{animation:fadeUp .4s ease both}
.kpi-card:nth-child(1){animation-delay:0ms}.kpi-card:nth-child(2){animation-delay:70ms}.kpi-card:nth-child(3){animation-delay:140ms}.kpi-card:nth-child(4){animation-delay:210ms}
.dash-card{animation:fadeUp .45s ease both}
.dark .kpi-card{background:linear-gradient(135deg,#16203A 0%,#131B2E 62%);border-color:var(--bcd,#1F293D)}
.dark .dash-card{background:#131B2E;border-color:#1F293D}
.dark .kpi-value{color:var(--vcd,#F1F5F9)}
.dark .dct{color:#F1F5F9}
.dark .kpi-bottom{border-top-color:#1F293D}
.dark .dch{border-bottom-color:#1F293D}
.dark .ot tr:hover td{background:rgba(109,93,246,.07)}
.dark .dl-item:hover{background:rgba(255,255,255,.05)}
.dark .pbr{background:#1E293B}
.dark .kpi-card::after{opacity:.12}
</style>

{{-- KPI CARDS --}}
<div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-5">

@php
function sparkPath(array $pts, float $w=110, float $h=36): array {
    $mn=min($pts); $mx=max($pts)?:1;
    $coords=array_map(function($v,$i) use($pts,$mn,$mx,$w,$h){
        $x=$i*(($w)/(count($pts)-1));
        $y=$h-((($v-$mn)/($mx-$mn?:1))*($h-8))-4;
        return "{$x},{$y}";
    },$pts,array_keys($pts));
    $d='M '.$coords[0];
    for($i=0;$i<count($coords)-1;$i++){
        [$px,$py]=explode(',',$coords[$i]);
        [$nx,$ny]=explode(',',$coords[$i+1]);
        $mx2=($px+$nx)/2;
        $d.=" C {$mx2},{$py} {$mx2},{$ny} {$nx},{$ny}";
    }
    return [$d, $d." L {$w},{$h} L 0,{$h} Z"];
}
[$spd1,$spa1]=sparkPath($salesSparkline);
[$spd2,$spa2]=sparkPath($ordersSparkline);
@endphp

<div class="kpi-card" style="--ac:#10B981;--tint:#ECFDF5;--vc:#059669;--vcd:#34D399;--bc:#D1FAE5;--bcd:#1D3B31;--hc:rgba(16,185,129,.2)">
  <div class="kpi-top">
    <span class="kpi-label">إجمالي المبيعات</span>
    <span class="kpi-badge {{ $salesGrowth>=0?'b-green':'b-red' }}">
      @if($salesGrowth>=0)<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/></svg>
      @else<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="22 17 13.5 8.5 8.5 13.5 2 7"/><polyline points="16 17 22 17 22 11"/></svg>@endif
      {{ abs($salesGrowth) }}% عن الشهر الماضي
    </span>
  </div>
  <div class="kpi-value">{{ number_format($totalSales,2) }}<span class="kpi-unit">ر.س</span></div>
  <div class="kpi-bottom">
    <span>معدل تحويل ممتاز</span>
    <svg width="110" height="36" viewBox="0 0 110 36" overflow="visible">
      <path d="{{ $spa1 }}" fill="rgba(16,185,129,.14)"/>
      <path d="{{ $spd1 }}" fill="none" stroke="#10B981" stroke-width="2.2" stroke-linecap="round"/>
    </svg>
  </div>
</div>

<div class="kpi-card" style="--ac:#6D5DF6;--tint:#EEF0FD;--vc:#5A47E5;--vcd:#9F8FF8;--bc:#DFE2FB;--bcd:#2A2A54;--hc:rgba(109,93,246,.2)">
  <div class="kpi-top">
    <span class="kpi-label">عدد الطلبات</span>
    <span class="kpi-badge {{ $ordersGrowth>=0?'b-green':'b-red' }}">
      @if($ordersGrowth>=0)<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/></svg>
      @else<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="22 17 13.5 8.5 8.5 13.5 2 7"/><polyline points="16 17 22 17 22 11"/></svg>@endif
      {{ abs($ordersGrowth) }}% عن الشهر الماضي
    </span>
  </div>
  <div class="kpi-value">{{ number_format($ordersCount) }}<span class="kpi-unit">طلبات</span></div>
  <div class="kpi-bottom">
    <span>مكتملة ومُعالجة</span>
    <svg width="110" height="36" viewBox="0 0 110 36" overflow="visible">
      <path d="{{ $spa2 }}" fill="rgba(109,93,246,.13)"/>
      <path d="{{ $spd2 }}" fill="none" stroke="#6D5DF6" stroke-width="2.2" stroke-linecap="round"/>
    </svg>
  </div>
</div>

<div class="kpi-card" style="--ac:#3B82F6;--tint:#EFF6FF;--vc:#2563EB;--vcd:#60A5FA;--bc:#DBEAFE;--bcd:#1E3350;--hc:rgba(59,130,246,.2)">
  <div class="kpi-top">
    <span class="kpi-label">عدد المنتجات</span>
    <span class="kpi-ic" style="background:linear-gradient(135deg,#3B82F6,#6366F1)">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></svg>
    </span>
  </div>
  <div class="kpi-value">{{ number_format($productsCount) }}<span class="kpi-unit">منتج</span></div>
  <div class="kpi-bottom">
    <span>متوفر في المتجر</span>
    <span class="kpi-badge b-blue">جاهز للطلب</span>
  </div>
</div>

<div class="kpi-card" style="--ac:#F59E0B;--tint:#FFFBEB;--vc:#D97706;--vcd:#FBBF24;--bc:#FDE68A;--bcd:#463A1B;--hc:rgba(245,158,11,.2)">
  <div class="kpi-top">
    <span class="kpi-label">عدد المستخدمين</span>
    <span class="kpi-ic" style="background:linear-gradient(135deg,#F59E0B,#F97316)">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
    </span>
  </div>
  <div class="kpi-value">{{ number_format($usersCount) }}<span class="kpi-unit">مستخدم</span></div>
  <div class="kpi-bottom">
    <span>عملاء مسجلون نشطون</span>
    <span class="kpi-badge b-amber">عميل مسجل</span>
  </div>
</div>
</div>

{{-- ROW 2: Sales Chart + Donut --}}
<div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-5">
  <div class="dash-card lg:col-span-2" style="--tc1:#6D5DF6;--tc2:#8B5CF6">
    <div class="dch">
      <div class="dch-l">
        <span class="hic" style="background:linear-gradient(135deg,#6D5DF6,#8B5CF6);--hs:rgba(109,93,246,.45)">
          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        </span>
        <div><div class="dct" id="chartTitle">المبيعات – آخر 30 يوماً</div><div class="dcs">تحليل بياني للإيرادات بالريال السعودي</div></div>
      </div>
      <div style="display:flex;gap:.35rem">
        <button class="ptab" id="tab7"  onclick="switchP(7)">7 أيام</button>
        <button class="ptab active" id="tab30" onclick="switchP(30)">30 يوماً</button>
        <button class="ptab" id="tab90" onclick="switchP(90)">90 يوماً</button>
      </div>
    </div>
    <div class="dcb" style="padding-bottom:1.2rem"><canvas id="salesChart" style="width:100%;max-height:215px" height="215"></canvas></div>
  </div>

  <div class="dash-card" style="--tc1:#F59E0B;--tc2:#F97316">
    <div class="dch">
      <div class="dch-l">
        <span class="hic" style="background:linear-gradient(135deg,#F59E0B,#F97316);--hs:rgba(245,158,11,.45)">
          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/></svg>
        </span>
        <div><div class="dct">توزيع حالات الطلبات</div><div class="dcs">نسبة الإنجاز ومعالجة الطلبات</div></div>
      </div>
    </div>
    <div class="dcb">
      <div style="display:flex;flex-direction:column;align-items:center;gap:.9rem">
        <div style="position:relative;width:155px;height:155px;flex-shrink:0">
          <canvas id="donutChart" width="155" height="155"></canvas>
          <div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;pointer-events:none">
            <span style="font-size:1.55rem;font-weight:800;color:#1E293B;line-height:1">{{ $totalOrdersForDonut }}</span>
            <span style="font-size:.62rem;color:#94A3B8;font-weight:600">إجمالي الطلبات</span>
          </div>
        </div>
        <div style="width:100%">
          @foreach($donutSlices as $sl)
            @if($sl['count']>0)
            <div class="dl-item">
              <div style="display:flex;align-items:center;gap:.45rem">
                <span style="width:9px;height:9px;border-radius:50%;background:{{ $sl['color'] }};flex-shrink:0"></span>
                <span style="font-size:.73rem;color:#475569;font-weight:600">{{ $sl['label'] }}</span>
              </div>
              <div style="display:flex;align-items:center;gap:.4rem">
                <span style="font-weight:800;font-size:.78rem;color:{{ $sl['color'] }}">{{ $sl['count'] }}</span>
                <span style="font-size:.62rem;color:#94A3B8">({{ round(($sl['count']/$totalOrdersForDonut)*100) }}%)</span>
              </div>
            </div>
            @endif
          @endforeach
          <div style="margin-top:.65rem;padding-top:.65rem;border-top:1px solid #F1F5F9;font-size:.68rem;color:#10B981;font-weight:700;display:flex;align-items:center;gap:.3rem">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg>
            نسبة تسليم ناجحة: {{ $deliveryRate }}%
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

{{-- ROW 3: Marketing + Top Products --}}
<div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-5">
  <div class="mcard">
    <div style="position:relative;z-index:1">
      <span style="display:inline-flex;align-items:center;gap:.35rem;background:rgba(255,255,255,.18);border-radius:20px;padding:.18rem .65rem;font-size:.62rem;font-weight:700;margin-bottom:.75rem">
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m12 3-1.9 5.8a2 2 0 0 1-1.3 1.3L3 12l5.8 1.9a2 2 0 0 1 1.3 1.3L12 21l1.9-5.8a2 2 0 0 1 1.3-1.3L21 12l-5.8-1.9a2 2 0 0 1-1.3-1.3Z"/></svg>
        نصيحة تسويقية ذكية
      </span>
      <h3 style="font-size:1.1rem;font-weight:800;line-height:1.4;margin-bottom:.55rem">زيادة مبيعات عطلة الأسبوع في "بركة عدن"</h3>
      <p style="font-size:.7rem;opacity:.84;line-height:1.65;margin-bottom:.9rem">الفساتين والعبايات الكلاسيكية تسجّل أعلى معدلات أسبوع. يمكنك إطلاق كوبون خصم 10% من قسم الخصومات للتحفيز على الشراء.</p>
      <div style="display:flex;align-items:center;justify-content:space-between">
        <a href="{{ \App\Filament\Resources\OrderResource::getUrl('index') }}" style="display:inline-flex;align-items:center;gap:.35rem;background:#fff;color:#6D5DF6;font-weight:700;font-size:.7rem;padding:.45rem .9rem;border-radius:9px;text-decoration:none">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect width="14" height="10" x="1" y="5" rx="1"/><polygon points="15 8 19 8 22 11 22 15 15 15 15 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>
          إدارة الطلبات
        </a>
        <div style="font-size:.68rem;opacity:.82;text-align:start">
          <div>الطلبات الجاهزة للشحن</div>
          <div style="font-size:1.05rem;font-weight:800">{{ $pendingShipments }} طلبات</div>
        </div>
      </div>
    </div>
  </div>

  <div class="dash-card lg:col-span-2" style="--tc1:#10B981;--tc2:#34D399">
    <div class="dch">
      <div class="dch-l">
        <span class="hic" style="background:linear-gradient(135deg,#10B981,#34D399);--hs:rgba(16,185,129,.45)">
          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg>
        </span>
        <div><div class="dct">المنتجات الأكثر مبيعاً</div><div class="dcs">أفضل الأصناف أداءً في متجر بركة عدن</div></div>
      </div>
      <a href="{{ \App\Filament\Resources\ProductResource::getUrl('index') }}" style="font-size:.7rem;font-weight:700;color:#6D5DF6;text-decoration:none">عرض الكل ←</a>
    </div>
    <div class="dcb" style="display:flex;flex-direction:column;gap:.8rem">
      @php $pgrads = [['#6D5DF6','#9F8FF8'],['#F59E0B','#FBBF24'],['#10B981','#34D399'],['#3B82F6','#60A5FA']]; @endphp
      @foreach($topProducts as $pr)
      <div style="display:flex;align-items:center;gap:.8rem">
        @if(!empty($pr->image))
          <img src="{{ $pr->image }}" alt="{{ $pr->name }}" style="width:42px;height:42px;border-radius:11px;object-fit:cover;flex-shrink:0;border:1px solid #E8EBF4"/>
        @else
          <div style="width:42px;height:42px;border-radius:11px;background:#EEF0FD;color:#6D5DF6;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:.78rem;flex-shrink:0">{{ mb_substr($pr->name,0,2) }}</div>
        @endif
        <div style="flex:1;min-width:0">
          <div style="display:flex;justify-content:space-between;align-items:center;gap:.4rem;margin-bottom:.18rem">
            <span style="font-size:.8rem;font-weight:700;color:#1E293B;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ $pr->name }}</span>
            <span style="font-size:.76rem;font-weight:800;color:#1E293B;white-space:nowrap;font-family:monospace">{{ number_format($pr->total_revenue??0) }} ر.س</span>
          </div>
          <div style="display:flex;justify-content:space-between;align-items:center;font-size:.66rem;color:#94A3B8;margin-bottom:.3rem">
            <span style="background:#F1F5F9;padding:.08rem .4rem;border-radius:5px;color:#64748B;font-weight:600">{{ $pr->category_name??'عام' }}</span>
            <span style="font-family:monospace;font-weight:600">{{ $pr->sales_count??0 }} مبيعة</span>
          </div>
          <div class="pbr"><div class="pbf" style="width:{{ $pr->percent??50 }}%;background:linear-gradient(90deg,{{ $pgrads[$loop->index % 4][0] }},{{ $pgrads[$loop->index % 4][1] }})"></div></div>
        </div>
      </div>
      @endforeach
    </div>
  </div>
</div>

{{-- ROW 4: Latest Orders --}}
<div class="dash-card" style="--tc1:#3B82F6;--tc2:#6366F1">
  <div class="dch">
    <div class="dch-l">
      <span class="hic" style="background:linear-gradient(135deg,#3B82F6,#6366F1);--hs:rgba(59,130,246,.45)">
        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/></svg>
      </span>
      <div><div class="dct">آخر الطلبات</div><div class="dcs">قائمة تفصيلية بأحدث المعاملات في المتجر</div></div>
    </div>
    <div style="display:flex;align-items:center;gap:.6rem">
      <select id="orderStatusFilter" class="fsel" onchange="filterOrders(this.value)">
        <option value="all">كل الحالات</option>
        <option value="processing">قيد المعالجة</option>
        <option value="shipped">قيد الشحن</option>
        <option value="delivered">مكتمل</option>
        <option value="cancelled">ملغي</option>
      </select>
      <a href="{{ \App\Filament\Resources\OrderResource::getUrl('index') }}" style="font-size:.7rem;font-weight:700;color:#6D5DF6;text-decoration:none;display:flex;align-items:center;gap:.3rem">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
        عرض الكل
      </a>
    </div>
  </div>
  <div style="overflow-x:auto">
    <table class="ot" id="ordersTable" style="width:100%;border-collapse:collapse">
      <thead><tr style="border-bottom:1px solid #F1F5F9">
        <th style="text-align:right;padding:.65rem 1.1rem;font-size:.65rem;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.06em;background:#F8FAFC;white-space:nowrap">رقم الطلب</th>
        <th style="text-align:right;padding:.65rem .8rem;font-size:.65rem;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.06em;background:#F8FAFC">العميل</th>
        <th style="text-align:right;padding:.65rem .8rem;font-size:.65rem;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.06em;background:#F8FAFC">الحالة</th>
        <th style="text-align:right;padding:.65rem .8rem;font-size:.65rem;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.06em;background:#F8FAFC">الإجمالي</th>
        <th style="text-align:right;padding:.65rem .8rem;font-size:.65rem;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.06em;background:#F8FAFC">التاريخ</th>
        <th style="padding:.65rem .8rem;background:#F8FAFC"></th>
      </tr></thead>
      <tbody>
        @forelse($latestOrders as $order)
        @php
          $sm=['pending'=>['l'=>'في الانتظار','c'=>'st-p','d'=>'#F59E0B'],'processing'=>['l'=>'قيد المعالجة','c'=>'st-r','d'=>'#F59E0B'],'shipped'=>['l'=>'قيد الشحن','c'=>'st-s','d'=>'#3B82F6'],'delivered'=>['l'=>'مكتمل','c'=>'st-d','d'=>'#10B981'],'cancelled'=>['l'=>'ملغي','c'=>'st-c','d'=>'#EF4444']];
          $st=$sm[$order->status]??['l'=>$order->status,'c'=>'st-p','d'=>'#94A3B8'];
          $ini=mb_substr($order->user?->name??'ع',0,2);
        @endphp
        <tr data-status="{{ $order->status }}" style="border-bottom:1px solid #F8FAFC;transition:background .15s">
          <td style="padding:.75rem 1.1rem">
            <a href="{{ \App\Filament\Resources\OrderResource::getUrl('view',['record'=>$order]) }}" style="font-weight:700;color:#6D5DF6;font-size:.78rem;text-decoration:none;font-family:monospace">{{ $order->order_number }}</a>
          </td>
          <td style="padding:.75rem .8rem">
            <div style="display:flex;align-items:center;gap:.55rem">
              <div class="av" style="background:linear-gradient(135deg,{{ $pgrads[$loop->index % 4][0] }},{{ $pgrads[$loop->index % 4][1] }})">{{ $ini }}</div>
              <div>
                <div style="font-size:.78rem;font-weight:700;color:#1E293B">{{ $order->user?->name??'عميل' }}</div>
                <div style="font-size:.65rem;color:#94A3B8">{{ $order->user?->email??'' }}</div>
              </div>
            </div>
          </td>
          <td style="padding:.75rem .8rem"><span class="sdt {{ $st['c'] }}"><span class="dot" style="background:{{ $st['d'] }}"></span>{{ $st['l'] }}</span></td>
          <td style="padding:.75rem .8rem;font-weight:800;font-size:.8rem;color:#1E293B;font-family:monospace;white-space:nowrap">{{ number_format($order->total,2) }} ر.س</td>
          <td style="padding:.75rem .8rem;font-size:.7rem;color:#94A3B8;white-space:nowrap">{{ $order->created_at->format('d/m/Y H:i') }}</td>
          <td style="padding:.75rem .8rem">
            <a href="{{ \App\Filament\Resources\OrderResource::getUrl('view',['record'=>$order]) }}" style="display:inline-flex;align-items:center;gap:.28rem;padding:.28rem .7rem;border-radius:7px;border:1px solid #E8EBF4;font-size:.68rem;font-weight:700;color:#6D5DF6;text-decoration:none;background:#fff" onmouseover="this.style.background='#EEF0FD'" onmouseout="this.style.background='#fff'">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
              عرض
            </a>
          </td>
        </tr>
        @empty
        <tr><td colspan="6" style="text-align:center;padding:2rem;color:#94A3B8;font-size:.85rem">لا توجد طلبات بعد</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
const DS=@json($chartDatasets);
const sCtx=document.getElementById('salesChart').getContext('2d');
const grad=sCtx.createLinearGradient(0,0,0,215);
grad.addColorStop(0,'rgba(109,93,246,0.32)');
grad.addColorStop(0.6,'rgba(109,93,246,0.08)');
grad.addColorStop(1,'rgba(109,93,246,0)');
const sc=new Chart(sCtx,{type:'line',data:{labels:DS['30'].labels,datasets:[{label:'المبيعات (ر.س)',data:DS['30'].data,borderColor:'#6D5DF6',backgroundColor:grad,borderWidth:2.8,fill:true,tension:0.4,pointBackgroundColor:'#fff',pointBorderColor:'#6D5DF6',pointBorderWidth:2.5,pointRadius:4,pointHoverRadius:6}]},options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false},tooltip:{rtl:true,textDirection:'rtl',padding:10,cornerRadius:10,backgroundColor:'#1E293B',callbacks:{label:c=>' '+c.raw.toLocaleString('ar')+' ر.س'}}},scales:{y:{grid:{color:'rgba(226,232,240,0.6)'},ticks:{font:{family:'Cairo',size:10},callback:v=>v.toLocaleString('ar')}},x:{grid:{display:false},ticks:{font:{family:'Cairo',size:10},maxTicksLimit:10,maxRotation:0,autoSkip:true}}}}});
const periodLabels={7:'المبيعات – آخر 7 أيام',30:'المبيعات – آخر 30 يوماً',90:'المبيعات – آخر 90 يوماً'};
function switchP(d){document.querySelectorAll('.ptab').forEach(t=>t.classList.remove('active'));document.getElementById('tab'+d).classList.add('active');sc.data.labels=DS[d].labels;sc.data.datasets[0].data=DS[d].data;sc.update();document.getElementById('chartTitle').textContent=periodLabels[d];}
const dSlices=@json($donutSlices);
const dF=dSlices.filter(s=>s.count>0);
new Chart(document.getElementById('donutChart').getContext('2d'),{type:'doughnut',data:{labels:dF.map(s=>s.label),datasets:[{data:dF.map(s=>s.count),backgroundColor:dF.map(s=>s.color),borderWidth:3,borderColor:'#fff',hoverBorderWidth:4}]},options:{cutout:'70%',responsive:false,plugins:{legend:{display:false},tooltip:{rtl:true,padding:8,cornerRadius:10,backgroundColor:'#1E293B',callbacks:{label:c=>' '+c.label+': '+c.raw}}}}});
function filterOrders(v){document.querySelectorAll('#ordersTable tbody tr[data-status]').forEach(tr=>{tr.style.display=(v==='all'||tr.dataset.status===v)?'':'none';});}
</script>
</x-filament-panels::page>