import React, { useState, useMemo } from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line
} from 'recharts';
import {
  LayoutDashboard,
  Megaphone,
  Percent,
  ShoppingCart,
  FileText,
  Package,
  Grid,
  Settings,
  Users,
  Search,
  Bell,
  Sun,
  Moon,
  TrendingUp,
  ChevronDown,
  ChevronRight,
  ChevronLeft,
  X,
  Menu,
  Eye,
  Store,
  Sparkles,
  Truck,
  RotateCcw,
  CheckCircle2,
  Clock,
  ArrowUpRight
} from 'lucide-react';

// ==========================================
// 1. DUMMY DATA (Matching Barakat Aden Store)
// ==========================================
const INITIAL_STATS = {
  totalSales: 19253.00,
  salesGrowth: 100,
  totalOrders: 6,
  ordersGrowth: 100,
  totalProducts: 17,
  totalUsers: 2,
};

const SALES_DATA_30_DAYS = [
  { date: '08/09', amount: 0 },
  { date: '11/09', amount: 450 },
  { date: '13/09', amount: 920 },
  { date: '15/09', amount: 600 },
  { date: '17/09', amount: 1400 },
  { date: '19/09', amount: 1100 },
  { date: '21/09', amount: 2150 },
  { date: '23/09', amount: 1800 },
  { date: '25/09', amount: 2600 },
  { date: '27/09', amount: 3100 },
  { date: '29/09', amount: 2450 },
  { date: '01/10', amount: 3900 },
  { date: '03/10', amount: 4500 },
  { date: '05/10', amount: 3800 },
  { date: '07/10', amount: 5000 },
  { date: '08/10', amount: 5800 },
];

const SALES_DATA_7_DAYS = [
  { date: '02/10', amount: 1200 },
  { date: '03/10', amount: 2400 },
  { date: '04/10', amount: 1800 },
  { date: '05/10', amount: 3450 },
  { date: '06/10', amount: 2900 },
  { date: '07/10', amount: 4200 },
  { date: '08/10', amount: 3303 },
];

const SALES_DATA_90_DAYS = [
  { date: 'يوليو 1', amount: 3200 },
  { date: 'يوليو 15', amount: 4800 },
  { date: 'أغسطس 1', amount: 6100 },
  { date: 'أغسطس 15', amount: 7400 },
  { date: 'سبتمبر 1', amount: 9200 },
  { date: 'سبتمبر 15', amount: 12400 },
  { date: 'أكتوبر 1', amount: 16100 },
  { date: 'أكتوبر 8', amount: 19253 },
];

const ORDER_STATUS_DATA = [
  { name: 'قيد المعالجة', value: 3, color: '#F59E0B' },
  { name: 'قيد الشحن', value: 2, color: '#3B82F6' },
  { name: 'مكتمل', value: 1, color: '#10B981' },
  { name: 'ملغي', value: 0, color: '#EF4444' },
];

const TOP_PRODUCTS = [
  {
    id: 1,
    name: 'فستان سهرة مطرز فاخر',
    category: 'فساتين سهرة',
    sales: 42,
    revenue: 18858,
    progress: 88,
    image: 'https://images.unsplash.com/photo-1566174049881-81001826583c?w=120&auto=format&fit=crop&q=80',
  },
  {
    id: 2,
    name: 'عباية مطرزة كلاسيكية',
    category: 'عبايات سوداء',
    sales: 31,
    revenue: 9269,
    progress: 72,
    image: 'https://images.unsplash.com/photo-1583391733956-375ef4cefee3?w=120&auto=format&fit=crop&q=80',
  },
  {
    id: 3,
    name: 'حجاب شيفون فاخر',
    category: 'حجابات',
    sales: 58,
    revenue: 2842,
    progress: 94,
    image: 'https://images.unsplash.com/photo-1611042553365-9b101c1c0e3a?w=120&auto=format&fit=crop&q=80',
  },
  {
    id: 4,
    name: 'حقيبة يد جلدية فاخرة',
    category: 'حقائب يد',
    sales: 18,
    revenue: 6282,
    progress: 54,
    image: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=120&auto=format&fit=crop&q=80',
  },
];

const RECENT_ORDERS = [
  { id: 'ORD-2026-00006', customer: 'أحمد محمد', date: 'منذ ساعتين', status: 'processing', statusLabel: 'قيد المعالجة', total: 5000.00, itemsCount: 4 },
  { id: 'ORD-2026-00005', customer: 'أحمد محمد', date: 'اليوم 11:30 ص', status: 'processing', statusLabel: 'قيد المعالجة', total: 10349.00, itemsCount: 8 },
  { id: 'ORD-2026-00004', customer: 'أحمد محمد', date: 'أمس 04:15 م', status: 'processing', statusLabel: 'قيد المعالجة', total: 871.00, itemsCount: 2 },
  { id: 'ORD-2026-00003', customer: 'أحمد محمد', date: '06/10/2026', status: 'shipped', statusLabel: 'قيد الشحن', total: 860.00, itemsCount: 3 },
  { id: 'ORD-2026-00002', customer: 'أحمد محمد', date: '05/10/2026', status: 'shipped', statusLabel: 'قيد الشحن', total: 673.00, itemsCount: 1 },
  { id: 'ORD-2026-00001', customer: 'سارة القحطاني', date: '03/10/2026', status: 'delivered', statusLabel: 'مكتمل', total: 1500.00, itemsCount: 2 },
];

const STATUS_BADGE = {
  pending: { bg: 'bg-amber-50 text-amber-600 border-amber-200 dark:bg-amber-950/40 dark:text-amber-400 dark:border-amber-800/40', dot: 'bg-amber-500' },
  processing: { bg: 'bg-orange-50 text-orange-600 border-orange-200 dark:bg-orange-950/40 dark:text-orange-400 dark:border-orange-800/40', dot: 'bg-orange-500' },
  shipped: { bg: 'bg-blue-50 text-blue-600 border-blue-200 dark:bg-blue-950/40 dark:text-blue-400 dark:border-blue-800/40', dot: 'bg-blue-500' },
  delivered: { bg: 'bg-emerald-50 text-emerald-600 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-400 dark:border-emerald-800/40', dot: 'bg-emerald-500' },
  cancelled: { bg: 'bg-rose-50 text-rose-600 border-rose-200 dark:bg-rose-950/40 dark:text-rose-400 dark:border-rose-800/40', dot: 'bg-rose-500' },
};

// ==========================================
// 2. SUB-COMPONENTS
// ==========================================

// Custom Tooltip for Recharts
const CustomAreaTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-slate-900/90 dark:bg-slate-800 text-white p-3 rounded-2xl shadow-xl border border-slate-700 text-xs backdrop-blur-md">
        <p className="text-slate-400 mb-1">التاريخ: {label}</p>
        <p className="text-sm font-black text-[#6D5DF6] dark:text-indigo-400 font-mono">
          {payload[0].value.toLocaleString()} ر.س
        </p>
      </div>
    );
  }
  return null;
};

// Mini Sparkline Component
const Sparkline = ({ data, color = "#6D5DF6" }) => {
  return (
    <div className="w-24 h-8">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={data}>
          <Line
            type="monotone"
            dataKey="v"
            stroke={color}
            strokeWidth={2.5}
            dot={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

// Top KPI Metric Card
const MetricCard = ({ title, value, unit, change, changeText, sparkData, sparkColor, icon: IconComponent, iconBg, iconColor, footerText }) => {
  return (
    <div className="bg-white dark:bg-[#131B2E] rounded-3xl p-5 border border-slate-100 dark:border-[#1F293D] shadow-[0_4px_20px_-2px_rgba(109,93,246,0.05)] hover:shadow-[0_12px_28px_-4px_rgba(109,93,246,0.12)] transition-all duration-300 group">
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs font-bold text-slate-500 dark:text-slate-400">{title}</span>
        {change !== undefined ? (
          <span className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-600 bg-emerald-50 dark:bg-emerald-950/40 px-2.5 py-0.5 rounded-full border border-emerald-100 dark:border-emerald-800/40">
            <TrendingUp size={12} />
            {change}% {changeText}
          </span>
        ) : (
          <div className={`w-8 h-8 rounded-xl ${iconBg} flex items-center justify-center ${iconColor}`}>
            {IconComponent && <IconComponent size={16} />}
          </div>
        )}
      </div>

      <div className="flex items-baseline justify-between mt-1">
        <div className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-slate-50 font-mono tracking-tight">
          {typeof value === 'number' ? value.toLocaleString() : value}
          <span className="text-xs font-bold text-slate-400 mr-1.5 font-sans">{unit}</span>
        </div>
      </div>

      <div className="mt-4 pt-3 border-t border-slate-50 dark:border-slate-800/60 flex items-center justify-between">
        <span className="text-[11px] text-slate-400 font-medium">{footerText}</span>
        {sparkData && <Sparkline data={sparkData} color={sparkColor} />}
      </div>
    </div>
  );
};

// ==========================================
// 3. MAIN DASHBOARD COMPONENT
// ==========================================
export default function BarakatAdenDashboard() {
  const [darkMode, setDarkMode] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeSection, setActiveSection] = useState('dashboard');
  const [chartPeriod, setChartPeriod] = useState('30');
  const [isChartEmpty, setIsChartEmpty] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [contentSubmenuOpen, setContentSubmenuOpen] = useState(false);

  // Active chart data
  const chartData = useMemo(() => {
    if (isChartEmpty) return [];
    if (chartPeriod === '7') return SALES_DATA_7_DAYS;
    if (chartPeriod === '90') return SALES_DATA_90_DAYS;
    return SALES_DATA_30_DAYS;
  }, [chartPeriod, isChartEmpty]);

  // Orders filtering
  const filteredOrders = useMemo(() => {
    return RECENT_ORDERS.filter((order) => {
      const matchSearch =
        order.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
        order.customer.includes(searchQuery) ||
        order.total.toString().includes(searchQuery);
      const matchStatus = statusFilter === 'all' || order.status === statusFilter;
      return matchSearch && matchStatus;
    });
  }, [searchQuery, statusFilter]);

  // Sidebar navigation sections
  const navItems = [
    { id: 'dashboard', label: 'لوحة التحكم', icon: LayoutDashboard },
    { id: 'marketing', label: 'التسويق', icon: Megaphone },
    { id: 'discounts', label: 'الخصومات', icon: Percent },
    { id: 'orders', label: 'الطلبات', icon: ShoppingCart, badge: '6' },
    {
      id: 'content',
      label: 'المحتوى',
      icon: FileText,
      hasSubmenu: true,
      subItems: [
        { id: 'pages', label: 'الصفحات' },
        { id: 'faqs', label: 'الأسئلة الشائعة' },
        { id: 'notifs', label: 'الإشعارات' },
        { id: 'banners', label: 'البنرات' },
      ],
    },
    { id: 'products', label: 'المنتجات', icon: Package, badge: '17' },
    { id: 'categories', label: 'التصنيفات', icon: Grid },
    { id: 'settings', label: 'الإعدادات', icon: Settings },
    { id: 'users', label: 'المستخدمون', icon: Users, badge: '2' },
  ];

  return (
    <div className={`min-h-screen ${darkMode ? 'dark bg-[#0B0F19] text-slate-100' : 'bg-[#F6F7FB] text-slate-800'} font-sans flex antialiased`} dir="rtl">
      
      {/* Mobile Backdrop */}
      {mobileMenuOpen && (
        <div
          onClick={() => setMobileMenuOpen(false)}
          className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-40 lg:hidden"
        />
      )}

      {/* ======================================================== */}
      {/* 1. SIDEBAR (COLLAPSIBLE & MOBILE DRAWER)                 */}
      {/* ======================================================== */}
      <aside
        className={`fixed lg:sticky top-0 right-0 h-screen z-40 flex flex-col justify-between bg-white dark:bg-[#131B2E] border-l border-slate-100 dark:border-[#1F293D] transition-all duration-300 select-none shadow-sm ${
          sidebarCollapsed ? 'w-20' : 'w-64'
        } ${mobileMenuOpen ? 'translate-x-0' : 'translate-x-full lg:translate-x-0'}`}
      >
        <div>
          {/* Logo & Header */}
          <div className="h-20 px-5 flex items-center justify-between border-b border-slate-100 dark:border-[#1F293D]">
            <div className={`flex items-center gap-3 overflow-hidden ${sidebarCollapsed ? 'justify-center w-full' : ''}`}>
              <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-[#6D5DF6] to-indigo-400 flex items-center justify-center text-white shadow-md flex-shrink-0">
                <Store size={22} />
              </div>
              {!sidebarCollapsed && (
                <div className="leading-tight">
                  <h1 className="font-black text-lg text-slate-800 dark:text-slate-100 tracking-tight flex items-center gap-1.5">
                    بركة عدن
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
                  </h1>
                  <span className="text-[11px] font-semibold text-slate-400">لوحة الإدارة الذكية</span>
                </div>
              )}
            </div>

            {!sidebarCollapsed && (
              <button
                onClick={() => setSidebarCollapsed(true)}
                className="hidden lg:flex p-1.5 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                title="طي القائمة الجانبية"
              >
                <ChevronRight size={18} />
              </button>
            )}
          </div>

          {/* Navigation Links */}
          <nav className="p-3 space-y-1.5 overflow-y-auto max-h-[calc(100vh-170px)]">
            {sidebarCollapsed && (
              <div className="flex justify-center pb-2">
                <button
                  onClick={() => setSidebarCollapsed(false)}
                  className="p-2 rounded-xl text-slate-400 hover:text-[#6D5DF6] hover:bg-indigo-50 dark:hover:bg-indigo-950 transition-colors"
                  title="توسيع القائمة"
                >
                  <ChevronLeft size={18} />
                </button>
              </div>
            )}

            {navItems.map((item) => {
              const isActive = activeSection === item.id;
              const isContent = item.id === 'content';
              const IconComp = item.icon;

              return (
                <div key={item.id}>
                  <button
                    onClick={() => {
                      if (isContent) {
                        setContentSubmenuOpen(!contentSubmenuOpen);
                      } else {
                        setActiveSection(item.id);
                      }
                      if (window.innerWidth < 1024 && !isContent) setMobileMenuOpen(false);
                    }}
                    className={`w-full flex items-center gap-3 px-3.5 py-3 rounded-2xl text-xs font-bold transition-all duration-200 group relative ${
                      isActive
                        ? 'bg-indigo-50 dark:bg-indigo-950/60 text-[#6D5DF6] dark:text-indigo-400 shadow-sm'
                        : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/40 hover:text-slate-900 dark:hover:text-slate-200'
                    } ${sidebarCollapsed ? 'justify-center px-0' : 'justify-between'}`}
                    title={sidebarCollapsed ? item.label : ''}
                  >
                    <div className="flex items-center gap-3">
                      <span
                        className={`p-1.5 rounded-xl transition-colors ${
                          isActive
                            ? 'bg-[#6D5DF6] text-white shadow-sm'
                            : 'text-slate-400 group-hover:text-[#6D5DF6]'
                        }`}
                      >
                        <IconComp size={18} />
                      </span>
                      {!sidebarCollapsed && <span>{item.label}</span>}
                    </div>

                    {!sidebarCollapsed && (
                      <div className="flex items-center gap-1.5">
                        {item.badge && (
                          <span
                            className={`px-2 py-0.5 rounded-full text-[11px] font-mono font-bold ${
                              isActive
                                ? 'bg-indigo-200/60 dark:bg-indigo-800 text-indigo-800 dark:text-indigo-200'
                                : 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400'
                            }`}
                          >
                            {item.badge}
                          </span>
                        )}
                        {item.hasSubmenu && (
                          <ChevronDown
                            size={14}
                            className={`transition-transform duration-200 ${
                              contentSubmenuOpen ? 'rotate-180' : ''
                            }`}
                          />
                        )}
                      </div>
                    )}
                  </button>

                  {/* Content Submenu */}
                  {isContent && contentSubmenuOpen && !sidebarCollapsed && (
                    <div className="mr-9 mt-1 space-y-1 border-r-2 border-slate-100 dark:border-slate-800 pr-2">
                      {item.subItems.map((sub) => (
                        <button
                          key={sub.id}
                          onClick={() => {
                            setActiveSection(sub.id);
                            if (window.innerWidth < 1024) setMobileMenuOpen(false);
                          }}
                          className={`w-full text-right px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                            activeSection === sub.id
                              ? 'text-[#6D5DF6] dark:text-indigo-400 bg-indigo-50/50 dark:bg-indigo-950/30 font-bold'
                              : 'text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200'
                          }`}
                        >
                          • {sub.label}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </nav>
        </div>

        {/* User Card at bottom */}
        <div className="p-3 border-t border-slate-100 dark:border-[#1F293D]">
          <div
            className={`flex items-center gap-3 p-2.5 rounded-2xl bg-slate-50 dark:bg-slate-800/40 border border-slate-100 dark:border-slate-800 ${
              sidebarCollapsed ? 'justify-center p-2' : ''
            }`}
          >
            <div className="relative flex-shrink-0">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#6D5DF6] to-indigo-400 text-white flex items-center justify-center font-bold text-sm shadow-sm">
                م
              </div>
              <span className="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full bg-emerald-500 border-2 border-white dark:border-[#131B2E]"></span>
            </div>
            {!sidebarCollapsed && (
              <div className="flex-1 min-w-0">
                <p className="text-xs font-bold text-slate-800 dark:text-slate-100 truncate">مدير المتجر</p>
                <p className="text-[11px] text-slate-400 truncate">admin@store.test</p>
              </div>
            )}
          </div>
        </div>
      </aside>

      {/* ======================================================== */}
      {/* 2. MAIN APPLICATION CONTENT                              */}
      {/* ======================================================== */}
      <main className="flex-1 min-w-0 flex flex-col min-h-screen">
        
        {/* TOP HEADER */}
        <header className="h-20 bg-white/80 dark:bg-[#131B2E]/80 backdrop-blur-md sticky top-0 z-30 border-b border-slate-100 dark:border-[#1F293D] px-4 sm:px-8 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3 flex-1 max-w-md">
            <button
              onClick={() => setMobileMenuOpen(true)}
              className="lg:hidden p-2 rounded-2xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300"
            >
              <Menu size={20} />
            </button>

            <div className="relative w-full">
              <span className="absolute inset-y-0 right-3.5 flex items-center pointer-events-none text-slate-400">
                <Search size={18} />
              </span>
              <input
                type="text"
                placeholder="بحث سريع في الطلبات، المنتجات، العملاء..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-[#F6F7FB] dark:bg-[#0B0F19] text-xs font-medium text-slate-800 dark:text-slate-200 placeholder-slate-400 pl-4 pr-10 py-2.5 rounded-2xl border border-transparent focus:border-[#6D5DF6]/30 focus:bg-white dark:focus:bg-[#131B2E] focus:outline-none focus:ring-4 focus:ring-[#6D5DF6]/10 transition-all duration-200"
              />
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="hidden md:flex items-center gap-2 px-3.5 py-1.5 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-100 dark:border-emerald-800/40 text-emerald-600 dark:text-emerald-400 text-xs font-bold">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              متجر بركة عدن نشط
            </div>

            <button className="relative p-2.5 rounded-2xl bg-[#F6F7FB] dark:bg-[#0B0F19] hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 transition-colors border border-slate-100 dark:border-slate-800">
              <Bell size={18} />
              <span className="absolute top-1.5 left-1.5 w-2 h-2 rounded-full bg-rose-500 ring-2 ring-white dark:ring-slate-900"></span>
            </button>

            <button
              onClick={() => setDarkMode(!darkMode)}
              className="p-2.5 rounded-2xl bg-[#F6F7FB] dark:bg-[#0B0F19] hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 transition-colors border border-slate-100 dark:border-slate-800"
              title={darkMode ? 'الوضع النهاري' : 'الوضع الليلي'}
            >
              {darkMode ? <Sun size={18} /> : <Moon size={18} />}
            </button>
          </div>
        </header>

        {/* DASHBOARD BODY */}
        <div className="p-4 sm:p-8 space-y-8 flex-1">
          
          {/* Title bar & Controls */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h2 className="text-2xl sm:text-3xl font-black text-slate-800 dark:text-slate-100 tracking-tight">
                لوحة التحكم
              </h2>
              <p className="text-xs text-slate-400 font-medium mt-1">
                مرحباً بك مجدداً! ملخص مباشر لأداء ومبيعات متجر "بركة عدن".
              </p>
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={() => setIsChartEmpty(!isChartEmpty)}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-2xl text-xs font-bold text-slate-600 dark:text-slate-300 bg-white dark:bg-[#131B2E] border border-slate-200/80 dark:border-slate-800 hover:border-[#6D5DF6] hover:text-[#6D5DF6] transition-all shadow-sm"
              >
                <Sparkles size={15} className="text-[#6D5DF6]" />
                <span>{isChartEmpty ? 'عرض بيانات الرسم' : 'معاينة حالة عدم وجود بيانات (Empty State)'}</span>
              </button>
            </div>
          </div>

          {/* ======================================================== */}
          {/* 3. TOP KPI CARDS (4 CARDS)                               */}
          {/* ======================================================== */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            <MetricCard
              title="إجمالي المبيعات"
              value={INITIAL_STATS.totalSales}
              unit="ر.س"
              change={INITIAL_STATS.salesGrowth}
              changeText="عن الشهر الماضي"
              footerText="معدل تحويل ممتاز"
              sparkData={[{ v: 7 }, { v: 3 }, { v: 4 }, { v: 5 }, { v: 6 }, { v: 8 }, { v: 9 }]}
              sparkColor="#10B981"
            />
            <MetricCard
              title="عدد الطلبات"
              value={INITIAL_STATS.totalOrders}
              unit="طلبات"
              change={INITIAL_STATS.ordersGrowth}
              changeText="عن الشهر الماضي"
              footerText="مكتملة ومُعالجة"
              sparkData={[{ v: 3 }, { v: 5 }, { v: 4 }, { v: 6 }, { v: 5 }, { v: 7 }, { v: 8 }]}
              sparkColor="#6D5DF6"
            />
            <MetricCard
              title="عدد المنتجات"
              value={INITIAL_STATS.totalProducts}
              unit="منتج"
              icon={Package}
              iconBg="bg-blue-50 dark:bg-blue-900/30"
              iconColor="text-blue-500"
              footerText="متوفر في المتجر"
            />
            <MetricCard
              title="عدد المستخدمين"
              value={INITIAL_STATS.totalUsers}
              unit="مستخدم"
              icon={Users}
              iconBg="bg-amber-50 dark:bg-amber-900/30"
              iconColor="text-amber-500"
              footerText="عميل مسجل"
            />
          </div>

          {/* ======================================================== */}
          {/* 4. CHARTS SECTION (Area Chart & Donut)                   */}
          {/* ======================================================== */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* Sales Area Chart */}
            <div className="lg:col-span-2 bg-white dark:bg-[#131B2E] rounded-3xl p-6 border border-slate-100 dark:border-[#1F293D] shadow-sm flex flex-col justify-between">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
                <div>
                  <h3 className="text-base font-bold text-slate-800 dark:text-slate-100">
                    المبيعات - آخر {chartPeriod === '7' ? '7 أيام' : chartPeriod === '30' ? '30 يوماً' : '90 يوماً'}
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">تحليل بياني لحجم المبيعات والإيرادات بالريال السعودي</p>
                </div>

                <div className="flex items-center bg-[#F6F7FB] dark:bg-[#0B0F19] p-1 rounded-2xl border border-slate-100 dark:border-slate-800">
                  {['7', '30', '90'].map((p) => (
                    <button
                      key={p}
                      onClick={() => { setChartPeriod(p); setIsChartEmpty(false); }}
                      className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                        chartPeriod === p && !isChartEmpty
                          ? 'bg-white dark:bg-[#131B2E] text-[#6D5DF6] dark:text-indigo-400 shadow-sm'
                          : 'text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
                      }`}
                    >
                      {p === '7' ? '7 أيام' : p === '30' ? '30 يوماً' : '90 يوماً'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Chart Canvas or Empty State */}
              {isChartEmpty || chartData.length === 0 ? (
                <div className="h-72 flex flex-col items-center justify-center text-center p-6 bg-slate-50/50 dark:bg-slate-900/30 rounded-2xl border border-dashed border-slate-200 dark:border-slate-800">
                  <div className="w-16 h-16 rounded-2xl bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-[#6D5DF6] mb-3">
                    <TrendingUp size={32} />
                  </div>
                  <h4 className="text-base font-bold text-slate-800 dark:text-slate-100 mb-1">
                    لا توجد مبيعات مسجلة في هذه الفترة
                  </h4>
                  <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm mb-4">
                    ابدأ بنشر رابط متجر بركة عدن أو إطلاق حملة تسويقية جديدة عبر قسم التسويق لتحفيز الطلبات.
                  </p>
                  <button
                    onClick={() => setIsChartEmpty(false)}
                    className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold text-[#6D5DF6] bg-white dark:bg-slate-800 border border-indigo-200 dark:border-indigo-800 rounded-xl hover:bg-indigo-50 transition-colors"
                  >
                    <RotateCcw size={14} />
                    استعادة البيانات النموذجية
                  </button>
                </div>
              ) : (
                <div className="h-72 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <defs>
                        <linearGradient id="salesGradient" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#6D5DF6" stopOpacity={0.4} />
                          <stop offset="95%" stopColor="#6D5DF6" stopOpacity={0.0} />
                        </linearGradient>
                      </defs>
                      <XAxis dataKey="date" stroke="#94A3B8" fontSize={11} tickLine={false} axisLine={false} />
                      <YAxis stroke="#94A3B8" fontSize={11} tickLine={false} axisLine={false} tickFormatter={(val) => `${val} ر.س`} />
                      <Tooltip content={<CustomAreaTooltip />} />
                      <Area
                        type="monotone"
                        dataKey="amount"
                        stroke="#6D5DF6"
                        strokeWidth={3}
                        fillOpacity={1}
                        fill="url(#salesGradient)"
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              )}
            </div>

            {/* Donut Chart: Order Status */}
            <div className="bg-white dark:bg-[#131B2E] rounded-3xl p-6 border border-slate-100 dark:border-[#1F293D] shadow-sm flex flex-col justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-800 dark:text-slate-100">
                  توزيع حالات الطلبات
                </h3>
                <p className="text-xs text-slate-400 mt-0.5">نسبة الإنجاز ومعالجة طلبات العملاء</p>
              </div>

              <div className="h-48 relative flex items-center justify-center my-3">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={ORDER_STATUS_DATA}
                      cx="50%"
                      cy="50%"
                      innerRadius={55}
                      outerRadius={75}
                      paddingAngle={4}
                      dataKey="value"
                    >
                      {ORDER_STATUS_DATA.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none text-center">
                  <span className="text-2xl font-black text-slate-800 dark:text-slate-100 font-mono">6</span>
                  <span className="text-[11px] text-slate-400 font-semibold">إجمالي الطلبات</span>
                </div>
              </div>

              <div className="space-y-2">
                {ORDER_STATUS_DATA.map((item, idx) => (
                  <div key={idx} className="flex items-center justify-between text-xs p-1.5 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: item.color }} />
                      <span className="text-slate-600 dark:text-slate-300 font-medium">{item.name}</span>
                    </div>
                    <span className="font-mono font-bold text-slate-800 dark:text-slate-200">{item.value}</span>
                  </div>
                ))}
              </div>
            </div>

          </div>

          {/* ======================================================== */}
          {/* 5. TOP SELLING PRODUCTS & BANNER                         */}
          {/* ======================================================== */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 bg-white dark:bg-[#131B2E] rounded-3xl p-6 border border-slate-100 dark:border-[#1F293D] shadow-sm">
              <div className="flex items-center justify-between mb-5">
                <div>
                  <h3 className="text-base font-bold text-slate-800 dark:text-slate-100">
                    المنتجات الأكثر مبيعاً
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">أفضل الأصناف أداءً وإقبالاً في متجر بركة عدن</p>
                </div>
              </div>

              <div className="space-y-4">
                {TOP_PRODUCTS.map((prod) => (
                  <div
                    key={prod.id}
                    className="flex items-center gap-4 p-3 rounded-2xl hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors group"
                  >
                    <img
                      src={prod.image}
                      alt={prod.name}
                      className="w-12 h-12 rounded-2xl object-cover shadow-sm group-hover:scale-105 transition-transform"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-2">
                        <h4 className="text-xs font-bold text-slate-800 dark:text-slate-100 truncate">
                          {prod.name}
                        </h4>
                        <span className="text-xs font-bold text-slate-900 dark:text-slate-200 font-mono flex-shrink-0">
                          {prod.revenue.toLocaleString()} ر.س
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-[11px] text-slate-400 mt-1">
                        <span>{prod.category}</span>
                        <span className="font-mono">{prod.sales} مبيعات</span>
                      </div>
                      <div className="w-full bg-slate-100 dark:bg-slate-800 h-1.5 rounded-full overflow-hidden mt-2">
                        <div
                          className="bg-[#6D5DF6] h-full rounded-full transition-all duration-500"
                          style={{ width: `${prod.progress}%` }}
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Smart Store Recommendation Card */}
            <div className="bg-gradient-to-br from-[#6D5DF6] to-indigo-700 rounded-3xl p-6 text-white shadow-lg flex flex-col justify-between relative overflow-hidden">
              <div className="absolute -top-12 -left-12 w-44 h-44 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
              <div>
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/20 backdrop-blur-md text-[11px] font-bold mb-4">
                  <Sparkles size={13} />
                  نصيحة تسويقية ذكية
                </span>
                <h3 className="text-lg font-black leading-snug mb-2">
                  عروض نهاية الموسم في "بركة عدن"
                </h3>
                <p className="text-xs text-white/80 leading-relaxed">
                  الفساتين والعبايات المطرزة تحظى بطلب عالي. أطلق كود خصم ترويجي من قسم الخصومات لتحفيز إتمام السلات المتروكة.
                </p>
              </div>

              <div className="mt-6 pt-4 border-t border-white/20 flex items-center justify-between">
                <div>
                  <p className="text-[11px] text-white/70">الطلبات الجاهزة للشحن</p>
                  <p className="text-xl font-bold font-mono">2 طلبات</p>
                </div>
                <button
                  onClick={() => setActiveSection('orders')}
                  className="px-4 py-2 rounded-xl bg-white text-indigo-700 text-xs font-bold hover:bg-slate-100 transition-colors shadow-sm"
                >
                  إدارة الطلبات
                </button>
              </div>
            </div>
          </div>

          {/* ======================================================== */}
          {/* 6. RECENT ORDERS TABLE (EXACT MATCH TO FILAMENT DATA)     */}
          {/* ======================================================== */}
          <div className="bg-white dark:bg-[#131B2E] rounded-3xl p-6 border border-slate-100 dark:border-[#1F293D] shadow-sm">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
              <div>
                <h3 className="text-base font-bold text-slate-800 dark:text-slate-100">
                  آخر الطلبات
                </h3>
                <p className="text-xs text-slate-400 mt-0.5">قائمة تفصيلية بأحدث طلبات الشراء الواردة</p>
              </div>

              <div className="flex items-center gap-3">
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="bg-[#F6F7FB] dark:bg-[#0B0F19] text-xs font-semibold text-slate-700 dark:text-slate-300 py-2.5 px-4 rounded-2xl border border-slate-100 dark:border-slate-800 focus:outline-none focus:border-[#6D5DF6]"
                >
                  <option value="all">كل الحالات</option>
                  <option value="processing">قيد المعالجة</option>
                  <option value="shipped">قيد الشحن</option>
                  <option value="delivered">مكتمل</option>
                  <option value="cancelled">ملغي</option>
                </select>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead>
                  <tr className="border-b border-slate-100 dark:border-slate-800 text-slate-400 font-bold">
                    <th className="pb-3.5 pr-4">رقم الطلب</th>
                    <th className="pb-3.5">العميل</th>
                    <th className="pb-3.5">الحالة</th>
                    <th className="pb-3.5">الإجمالي</th>
                    <th className="pb-3.5 pl-4 text-left">الإجراء</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-50 dark:divide-slate-800/60">
                  {filteredOrders.length === 0 ? (
                    <tr>
                      <td colSpan="5" className="py-12 text-center text-slate-400">
                        لا توجد طلبات تطابق معايير البحث
                      </td>
                    </tr>
                  ) : (
                    filteredOrders.map((order) => {
                      const badge = STATUS_BADGE[order.status] || STATUS_BADGE.pending;
                      const initials = order.customer
                        .split(' ')
                        .map((n) => n[0])
                        .slice(0, 2)
                        .join('');

                      return (
                        <tr
                          key={order.id}
                          className="hover:bg-slate-50/80 dark:hover:bg-slate-800/40 transition-colors group cursor-pointer"
                          onClick={() => setSelectedOrder(order)}
                        >
                          <td className="py-4 pr-4 font-mono font-bold text-slate-800 dark:text-slate-100">
                            <span className="hover:text-[#6D5DF6] transition-colors">{order.id}</span>
                          </td>
                          <td className="py-4">
                            <div className="flex items-center gap-2.5">
                              <div className="w-8 h-8 rounded-xl bg-indigo-50 dark:bg-indigo-900/30 text-[#6D5DF6] font-bold flex items-center justify-center text-xs">
                                {initials}
                              </div>
                              <div>
                                <p className="font-bold text-slate-800 dark:text-slate-200">{order.customer}</p>
                                <p className="text-[10px] text-slate-400">{order.date}</p>
                              </div>
                            </div>
                          </td>
                          <td className="py-4">
                            <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold border ${badge.bg}`}>
                              <span className={`w-1.5 h-1.5 rounded-full ${badge.dot}`}></span>
                              {order.statusLabel}
                            </span>
                          </td>
                          <td className="py-4 font-mono font-bold text-slate-900 dark:text-slate-100">
                            {order.total.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                            <span className="text-[11px] text-slate-400 mr-1 font-sans font-normal">ر.س</span>
                          </td>
                          <td className="py-4 pl-4 text-left">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setSelectedOrder(order);
                              }}
                              className="px-3.5 py-1.5 rounded-xl font-bold text-xs text-[#6D5DF6] bg-indigo-50 dark:bg-indigo-950/60 hover:bg-[#6D5DF6] hover:text-white transition-all shadow-sm"
                            >
                              عرض
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>

        </div>

        {/* FOOTER */}
        <footer className="px-8 py-4 border-t border-slate-100 dark:border-[#1F293D] text-xs text-slate-400 flex flex-col sm:flex-row items-center justify-between gap-2">
          <p>© 2026 متجر بركة عدن. جميع الحقوق محفوظة.</p>
          <div className="flex items-center gap-4">
            <span>لوحة تحكم SaaS المطوّرة</span>
            <span>•</span>
            <span className="text-emerald-500 font-bold flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span> متصل
            </span>
          </div>
        </footer>
      </main>

      {/* ORDER DETAILS POPUP MODAL */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-[#131B2E] rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-100 dark:border-slate-800 relative">
            <button
              onClick={() => setSelectedOrder(null)}
              className="absolute left-5 top-5 p-2 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800"
            >
              <X size={18} />
            </button>
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 rounded-2xl bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-[#6D5DF6] font-mono font-bold">
                #
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-800 dark:text-slate-100">{selectedOrder.id}</h3>
                <p className="text-xs text-slate-400">العميل: {selectedOrder.customer}</p>
              </div>
            </div>
            <div className="bg-slate-50 dark:bg-slate-800/40 p-4 rounded-2xl space-y-2 text-xs mb-6">
              <div className="flex justify-between">
                <span className="text-slate-400">حالة الطلب:</span>
                <span className="font-bold text-orange-600">{selectedOrder.statusLabel}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">عدد المنتجات:</span>
                <span className="font-bold">{selectedOrder.itemsCount} عناصر</span>
              </div>
              <div className="pt-2 border-t border-slate-200 dark:border-slate-700/60 flex justify-between items-center">
                <span className="font-bold">المبلغ الإجمالي:</span>
                <span className="text-lg font-black text-[#6D5DF6] font-mono">
                  {selectedOrder.total.toLocaleString()} ر.س
                </span>
              </div>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setSelectedOrder(null)}
                className="flex-1 py-2.5 px-4 rounded-xl text-xs font-bold text-slate-600 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 transition-colors"
              >
                إغلاق
              </button>
              <button
                onClick={() => { alert(`تم تحديث الطلب ${selectedOrder.id}`); setSelectedOrder(null); }}
                className="flex-1 py-2.5 px-4 rounded-xl text-xs font-bold text-white bg-[#6D5DF6] hover:bg-indigo-600 transition-colors shadow-sm"
              >
                تحديث الحالة
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
