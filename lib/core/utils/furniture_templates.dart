import '../../models/furniture_section_model.dart';

class FurnitureTemplates {
  /// Available section types with Arabic display names
  static const List<Map<String, String>> availableSectionTypes = [
    {'type': 'غرفة نوم رئيسية', 'label': 'غرفة نوم رئيسية', 'icon': 'bed'},
    {'type': 'غرفة أطفال', 'label': 'غرفة أطفال / شبابي', 'icon': 'bedroom_baby'},
    {'type': 'انتريه وصالون', 'label': 'انتريه / صالون / كنب', 'icon': 'weekend'},
    {'type': 'سفرة', 'label': 'غرفة سفرة', 'icon': 'table_restaurant'},
    {'type': 'مطبخ', 'label': 'مطبخ كامل / وحدات', 'icon': 'kitchen'},
    {'type': 'مكتب', 'label': 'مكتب / أثاث مكتبي', 'icon': 'desk'},
    {'type': 'وحدة تلفزيون', 'label': 'وحدة تلفزيون وبانيل', 'icon': 'tv'},
    {'type': 'دولاب منفصل', 'label': 'دولاب منفصل / دريسنج', 'icon': 'door_sliding'},
    {'type': 'أثاث مخصص', 'label': 'قطعة مخصصة بتصميم خاص', 'icon': 'design_services'},
  ];

  /// Generate default components for a given section type
  static List<FurnitureComponentModel> generateDefaultComponents(String sectionType) {
    switch (sectionType) {
      case 'غرفة نوم رئيسية':
        return [
          FurnitureComponentModel(
            name: 'سرير كينج رئيسي',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 160,
              'length': 200,
              'height': 120,
              'unit': 'سم',
              'headboard': 'عرض 160 × ارتفاع 120',
              'base_type': 'ملل خشب زان مكبوسة',
            },
            specs: {
              'wood_type': 'كونتر محشو زان',
              'thickness': '18 مم',
              'has_upholstery': true,
              'fabric_type': 'قماش قطيفة عالي الكثافة',
              'fabric_code': 'حسب اختيار العميل',
              'finish': 'دهان دوكو مط',
              'storage_drawers': 'سحارة باكم هيدروليك',
            },
            notes: 'قاعدة سرير قوية ومبطنة',
          ),
          FurnitureComponentModel(
            name: 'كومودينو جانبي',
            category: sectionType,
            quantity: 2,
            dimensions: {
              'width': 50,
              'depth': 45,
              'height': 55,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'MDF عالي الكثافة مع زان',
              'thickness': '18 مم',
              'drawers_count': 2,
              'handles': 'مقابض استانلس ذهبي مودرن',
              'finish': 'دوكو فرن مط',
            },
            notes: 'مجاري أدراج مرحلتين سوفت كلوز',
          ),
          FurnitureComponentModel(
            name: 'تسريحة مودرن',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 140,
              'depth': 50,
              'height': 85,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر زان 18 مم',
              'thickness': '18 مم',
              'drawers_count': 6,
              'has_mirror': true,
              'mirror_count': 1,
              'mirror_dimensions': '100×80 سم',
              'glass_thickness': '6 مم بلجيكي مشطوف',
              'lighting': 'ليد وورم مخفي خلف المراية',
              'finish': 'دهان دوكو مط مع تطعيم خشب طبيعي',
            },
            notes: 'تقسيمات داخلية في الدرج العلوي للإكسسوارات',
          ),
          FurnitureComponentModel(
            name: 'مراية تسريحة منفصلة',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 80,
              'height': 100,
              'depth': 4,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'إطار خشب زان',
              'glass_thickness': '6 مم عاكس نقي',
              'lighting': 'إضاءة محيطية LED',
              'finish': 'مطابق للتسريحة',
            },
            notes: 'شاسيه تثبيت جداري مخفي',
          ),
          FurnitureComponentModel(
            name: 'دولاب ملابس كبير',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 260,
              'depth': 65,
              'height': 240,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر اندونيسي عالي الجودة',
              'thickness': '18 مم للجسم والأرفف',
              'back_spec': 'أبلكاش سيه 6 مم',
              'doors_count': 3,
              'door_type': 'جرار ميكانيزم تركي ثقيل',
              'shelves_count': 6,
              'drawers_count': 4,
              'internal_partitions': 'شماعتين طويلة وقصيرة + خزانة أمان',
              'has_mirror': true,
              'mirror_dimensions': 'مراية كاملة على الدلفة الوسطى',
              'finish': 'أرو قشرة طبيعي أو دوكو مط',
              'hinges_accessories': 'مجاري هافي كينج مع مخمدات صدمات',
            },
            notes: 'إضاءة حساس داخلية عند فتح الأبواب',
          ),
        ];

      case 'غرفة أطفال':
        return [
          FurnitureComponentModel(
            name: 'سرير أطفال 120 سم',
            category: sectionType,
            quantity: 2,
            dimensions: {
              'width': 120,
              'length': 195,
              'height': 100,
              'unit': 'سم',
              'headboard': 'ارتفاع الظهر 100 سم',
              'base_type': 'ملل خشب سويد 2.5 سم',
            },
            specs: {
              'wood_type': 'خشب زان مع ألواح MDF',
              'thickness': '18 مم',
              'has_upholstery': true,
              'fabric_type': 'جلد مقلوب مقاوم للبقع',
              'finish': 'دوكو ألوان مبهجة حسب الطلب',
            },
            notes: 'حواف دائرية آمنة للأطفال',
          ),
          FurnitureComponentModel(
            name: 'دولاب أطفال ودود',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 160,
              'depth': 60,
              'height': 220,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر 18 مم',
              'thickness': '18 مم',
              'doors_count': 3,
              'door_type': 'مفصلي باكم',
              'shelves_count': 5,
              'drawers_count': 2,
              'finish': 'دهان دوكو أبيض مع لمسات ألوان',
            },
            notes: 'تقسيمات ملابس أطفال وأرفف ألعاب',
          ),
          FurnitureComponentModel(
            name: 'كومود أطفال',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 45,
              'depth': 40,
              'height': 50,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'MDF مستورد',
              'drawers_count': 2,
              'finish': 'دوكو',
            },
          ),
          FurnitureComponentModel(
            name: 'مكتب مذاكرة أطفال',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 120,
              'depth': 60,
              'height': 75,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر مع سطح HPL مقاوم للخدش',
              'thickness': '25 مم للسطح',
              'drawers_count': 3,
              'cable_holes': true,
              'finish': 'دوكو مط',
            },
            notes: 'وحدة أدراج جانبية مع مساحة للكمبيوتر',
          ),
          FurnitureComponentModel(
            name: 'مكتبة أرفف جدارية',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 100,
              'depth': 25,
              'height': 80,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'MDF 18 مم',
              'shelves_count': 3,
              'finish': 'مطابق للمكتب',
            },
            notes: 'تثبيت مخفي على الحائط للكتب والقصص',
          ),
        ];

      case 'انتريه وصالون':
        return [
          FurnitureComponentModel(
            name: 'كنبة رئيسية 3 مقاعد',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 225,
              'depth': 95,
              'height': 85,
              'unit': 'سم',
              'seat_height': '45 سم',
              'seat_depth': '60 سم',
            },
            specs: {
              'wood_type': 'خشب زان أحمر روماني مجفف كتل سميكة',
              'foam_type': 'إسفنج كابتونيه سوفت عالي الكثافة 36',
              'fabric_type': 'قماش كتان تركي ثقيل فاخر',
              'fabric_code': 'كود درجات البيج/الرمادي',
              'cushions_count': 5,
              'legs_type': 'أرجل خشب زان مدهونة استر مع كعب استانلس',
              'finish': 'تنجيد مودرن فاخر مع دبل استيتش',
            },
            notes: 'هيكل داخلي مدعم بأشرطة مطاطية ألماني وسوست سويدية',
          ),
          FurnitureComponentModel(
            name: 'كنبة 2 مقعد (لوف سيت)',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 175,
              'depth': 95,
              'height': 85,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'هيكل زان أحمر',
              'foam_type': 'إسفنج كثافة 36',
              'fabric_type': 'مطابق للكنبة الكبيرة',
              'cushions_count': 3,
              'legs_type': 'أرجل خشب زان',
            },
          ),
          FurnitureComponentModel(
            name: 'كرسي فوتيه مريح',
            category: sectionType,
            quantity: 2,
            dimensions: {
              'width': 85,
              'depth': 85,
              'height': 90,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'زان أحمر',
              'foam_type': 'إسفنج سوفت مريح كثافة 33',
              'fabric_type': 'قماش مشجر/سادة متناسق مع الطقم',
              'legs_type': 'أرجل خشب زان',
            },
            notes: 'تنجيد كابتونيه كلاسيك/مودرن للظهر',
          ),
          FurnitureComponentModel(
            name: 'ترابيزة وسط (كوفي تيبول)',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 120,
              'depth': 70,
              'height': 45,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'شاسيه زان مفرغ مع سطح رخام أو خشب',
              'top_material': 'قشرة أرو طبيعي مع حواف زان',
              'finish': 'استر بولي يوريثان مقاوم للحرارة والسوائل',
            },
          ),
          FurnitureComponentModel(
            name: 'ترابيزة جانبية (كورنر)',
            category: sectionType,
            quantity: 2,
            dimensions: {
              'width': 50,
              'depth': 50,
              'height': 55,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'خشب زان',
              'finish': 'مطابق لترابيزة الوسط',
            },
          ),
        ];

      case 'سفرة':
        return [
          FurnitureComponentModel(
            name: 'ترابيزة سفرة رئيسية',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 200,
              'depth': 100,
              'height': 78,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'زان أحمر مكبس كونتر محمل',
              'thickness': 'قرصة 4 سم مدبلة',
              'table_shape': 'مستطيل بحواف مائلة ناعمة',
              'top_material': 'قشرة جوز تركي طبيعي',
              'base_type': 'قاعدة مزدوجة حرف V خشب زان',
              'extension_mechanism': 'بدون سحاب ثابتة',
              'finish': 'استر بني جوزي لامع أو مط مقاوم للخدش',
            },
            notes: 'قرصة سطح قابلة للفك لسهولة النقل',
          ),
          FurnitureComponentModel(
            name: 'كراسي سفرة منجدة',
            category: sectionType,
            quantity: 6,
            dimensions: {
              'width': 50,
              'depth': 55,
              'height': 95,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'هيكل زان روماني كتل كاملة بدون لحامات ضعيفة',
              'upholstery': 'تنجيد كامل للظهر والمقعد',
              'foam_type': 'إسفنج ضغط عالي كثافة 33',
              'fabric_type': 'قماش قطيفة أو جلد ناعم',
              'legs_type': 'أرجل خشب زان مع تشطيب استر',
            },
            notes: 'متانة عالية للاستخدام اليومي',
          ),
          FurnitureComponentModel(
            name: 'بوفيه سفرة كبير',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 210,
              'depth': 50,
              'height': 90,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر مع قشرة طبيعي',
              'thickness': '18 مم',
              'doors_count': 4,
              'drawers_count': 3,
              'has_mirror': true,
              'mirror_dimensions': '200×80 سم',
              'hinges_accessories': 'مفصلات إيطالي باكم سوفت كلوز',
              'finish': 'استر مطابق للترابيزة',
            },
            notes: 'درج مبطن للملاعق والفضيات',
          ),
          FurnitureComponentModel(
            name: 'نيش سفرة مودرن',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 120,
              'depth': 45,
              'height': 200,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر مع إطارات زان',
              'doors_count': 2,
              'door_type': 'دلف زجاجية سيكوريت',
              'shelves_count': 4,
              'glass_thickness': 'أرفف زجاج 8 مم مشطوف كمبيوتر',
              'lighting': 'ليد سبوت لايت داخلي دافئ',
              'finish': 'استر أرو مع دهان خلفية مط',
            },
            notes: 'إضاءة داخلية تفتح بمفتاح لمس',
          ),
        ];

      case 'مطبخ':
        return [
          FurnitureComponentModel(
            name: 'وحدات مطبخ سفلية (متر طولي)',
            category: sectionType,
            quantity: 3,
            dimensions: {
              'width': 100,
              'depth': 60,
              'height': 88,
              'unit': 'سم',
            },
            specs: {
              'carcass_material': 'كونتر معالج بمادة الميلامين المقاومة للرطوبة',
              'facade_material': 'بولي لاك تركي لامع مقاوم للحرارة والخدش',
              'thickness': '18 مم للجسم والدلف',
              'doors_count': 2,
              'shelves_count': 1,
              'hinges_accessories': 'مفصلات هيدروليك استانلس 304 ضد الصدأ',
              'legs': 'أرجل بلاستيك مقوى مع وزرة ألومنيوم سفلية مانعة للأتربة',
              'countertop': 'حساب الرخام/الكوارتز اختياري',
            },
            notes: 'عزل فواصل وتلبيس شريط حرف 2 مم بالحرارة',
          ),
          FurnitureComponentModel(
            name: 'وحدة حوض المطبخ',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 90,
              'depth': 60,
              'height': 88,
              'unit': 'سم',
            },
            specs: {
              'carcass_material': 'فوم بورد PVC عازل للماء 100% أو كونتر معزول',
              'doors_count': 2,
              'plumbing_cutouts': 'فتحات سباكة جاهزة ومعزولة السيليكون',
              'floor_protection': 'صاج حماية سفلي ضد التسريب',
            },
            notes: 'مقاومة تامة للمياه والرطوبة',
          ),
          FurnitureComponentModel(
            name: 'وحدة أدراج مطبخ (تاندوم بوكس)',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 60,
              'depth': 60,
              'height': 88,
              'unit': 'سم',
            },
            specs: {
              'drawers_count': 3,
              'slides_type': 'مجاري تاندوم بوكس جوانب معدنية سوفت كلوز',
              'accessories': 'منظم ملاعق وتقسيمة توابل داخلية',
            },
            notes: 'تحمل أوزان حتى 35 كجم للدرج السفلي للحلل',
          ),
          FurnitureComponentModel(
            name: 'وحدات مطبخ علوية (متر طولي)',
            category: sectionType,
            quantity: 3,
            dimensions: {
              'width': 100,
              'depth': 35,
              'height': 80,
              'unit': 'سم',
            },
            specs: {
              'carcass_material': 'كونتر 18 مم',
              'facade_material': 'بولي لاك مطابق للوحدات السفلية',
              'doors_count': 2,
              'door_type': 'دلف قلاب هيدروليك باكم أفقي',
              'shelves_count': 2,
            },
            notes: 'تعليق شاسيه صلب مخفي قوي جداً على الحائط',
          ),
          FurnitureComponentModel(
            name: 'وحدة مطبخ للأجهزة البلت إن (عمود فرن وميكروويف)',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 60,
              'depth': 60,
              'height': 220,
              'unit': 'سم',
            },
            specs: {
              'appliance_cutouts': 'فتحة فرن 60 سم + فتحة ميكروويف بلت إن',
              'ventilation': 'فتحات تهوية خلفية مدروسة للأجهزة',
              'storage': 'دلفة خزين علوية ودلفة أو درجين سفليين',
            },
            notes: 'تحمل حراري عالي وعوازل',
          ),
        ];

      case 'مكتب':
        return [
          FurnitureComponentModel(
            name: 'مكتب مدير رئيسي',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 180,
              'depth': 80,
              'height': 76,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر محمل مع قشرة أرو أو سطح HPL',
              'thickness': 'قرصة مدبلة 36 مم',
              'cable_holes': 'فتحتين استانلس لتمرير كابلات الكمبيوتر والشواحن',
              'finish': 'استر أو دوكو فرن مط',
            },
            notes: 'شاسيه قوي مع مسافة مريحة للأرجل',
          ),
          FurnitureComponentModel(
            name: 'وحدة أدراج جانبية (سايد)',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 100,
              'depth': 50,
              'height': 65,
              'unit': 'سم',
            },
            specs: {
              'drawers_count': 3,
              'has_central_lock': true,
              'doors_count': 1,
              'finish': 'مطابق للمكتب الرئيسي',
            },
            notes: 'توضع يمين أو يسار المكتب حسب الغرفة',
          ),
          FurnitureComponentModel(
            name: 'مكتبة ملفات ودوسيهات',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 160,
              'depth': 40,
              'height': 200,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر 18 مم',
              'doors_count': 4,
              'door_type': 'دلف سفلية خشب ودلف علوية زجاج سيكوريت فاميه',
              'shelves_count': 4,
            },
            notes: 'أرفف قوية تتحمل أوزان الملفات الثقيلة',
          ),
        ];

      case 'وحدة تلفزيون':
        return [
          FurnitureComponentModel(
            name: 'وحدة تلفزيون معلقة (كونسول سفلي)',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 220,
              'depth': 35,
              'height': 35,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'MDF عالي الكثافة مع كونتر',
              'thickness': '18 مم',
              'doors_count': 2,
              'door_type': 'دلف قلاب هيدروليك بدون مقابض (تاتش بوش)',
              'drawers_count': 1,
              'cable_holes': 'ممر كابلات مخفي للشاشات والريسيفر',
              'finish': 'دهان دوكو مط مع تطعيم خشب طبيعي',
            },
            notes: 'تثبيت معلق جداري شاسيه حديد مخفي',
          ),
          FurnitureComponentModel(
            name: 'بانيل حائط خشبي مع ليد',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 220,
              'depth': 8,
              'height': 150,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'تكسيات بديل خشب أو قشرة طبيعي شرائح',
              'lighting': 'شريط ليد بروفايل ألومنيوم وورم مخفي',
              'finish': 'مطابق للكونسول',
            },
            notes: 'مجرى مخفي لكابلات الشاشة والكهرباء',
          ),
          FurnitureComponentModel(
            name: 'أرفف حائطية ديكورية',
            category: sectionType,
            quantity: 2,
            dimensions: {
              'width': 100,
              'depth': 20,
              'height': 5,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'خشب زان مكبوس سميك',
              'finish': 'دوكو أو استر',
            },
            notes: 'أرفف طائرة تثبيت مسامير مدفونة',
          ),
        ];

      case 'دولاب منفصل':
        return [
          FurnitureComponentModel(
            name: 'دولاب ملابس منفصل مودرن',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 240,
              'depth': 65,
              'height': 240,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'كونتر 18 مم محمل',
              'doors_count': 3,
              'door_type': 'جرار ميكانيزم سوفت كلوز',
              'shelves_count': 6,
              'drawers_count': 4,
              'has_mirror': true,
              'mirror_dimensions': 'مراية كاملة داخلية أو خارجية',
              'finish': 'دوكو أو قشرة أرو',
            },
            notes: 'تقسيمات داخلية حسب طلب العميل',
          ),
        ];

      case 'أثاث مخصص':
      default:
        return [
          FurnitureComponentModel(
            name: 'قطعة أثاث مخصصة (تصميم خاص)',
            category: sectionType,
            quantity: 1,
            dimensions: {
              'width': 100,
              'depth': 50,
              'height': 100,
              'unit': 'سم',
            },
            specs: {
              'wood_type': 'خشب زان / كونتر حسب الطلب',
              'thickness': '18 مم',
              'finish': 'حسب العينة المعتمدة',
            },
            notes: 'تنفيذ وفقًا للمخطط والرسومات الهندسية المعتمدة مع العميل',
          ),
        ];
    }
  }

  /// Suggestion lists for raw materials to allow quick auto-complete
  static const List<String> commonRawMaterials = [
    'أبلكاش كوري 3 مم',
    'أبلكاش سيه 6 مم',
    'ألواح MDF مستورد 18 مم',
    'ألواح MDF مستورد 12 مم',
    'كونتر اندونيسي 18 مم',
    'خشب زان روماني أحمر',
    'خشب سويد فنلندي',
    'قشرة أرو طبيعي',
    'قشرة جوز تركي',
    'دهانات وسيلر وبولي يوريثان',
    'دهان دوكو فرن',
    'مفصلات باكم هيدروليك',
    'مجاري أدراج مرحلتين',
    'مجاري تاندوم بوكس سوفت كلوز',
    'مقابض استانلس مودرن',
    'ألواح زجاج ومرايات بلجيكي',
    'مسامير وغراء ألماني بولي بوند',
    'قماش قطيفة تنجيد عالي الكثافة',
    'قماش كتان ثقيل',
    'جلد تركي تنجيد',
    'إسفنج مضغوط كثافة 36',
    'إسفنج سوفت كثافة 33',
    'أرجل خشب زان للأثاث',
    'أرجل استانلس ذهبي',
    'ميكانيزم سرير سحارة باكم',
    'ميكانيزم دولاب جرار تركي',
    'شريط حرف PVC حراري',
  ];

  /// Standard units of measurement
  static const List<String> standardUnits = [
    'لوح',
    'قطعة',
    'متر',
    'متر مربع',
    'متر مكعب',
    'طقم',
    'كجم',
    'لتر',
    'علبة',
    'شريط',
    'فرخ',
    'رول',
  ];
}
