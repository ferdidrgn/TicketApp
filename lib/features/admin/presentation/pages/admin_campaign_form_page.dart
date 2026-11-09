import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_mutation_provider.dart';
import '../widgets/admin_form_widgets.dart';

/// Kampanya (Campaign) ekleme/düzenleme formu. `campaign == null` -> yeni
/// kampanya; aksi halde düzenleme + silme (bkz. `AdminTeamFormPage`'daki
/// AYNI desen). Alan seti web yönetim paneliyle BİREBİR aynı
/// (`site/js/admin/schema.js` -> `Campaign`): title, imageUrl, url,
/// startDate, endDate (gün — saat yok).
class AdminCampaignFormPage extends ConsumerStatefulWidget {
  final Campaign? campaign;

  const AdminCampaignFormPage({super.key, this.campaign});

  @override
  ConsumerState<AdminCampaignFormPage> createState() =>
      _AdminCampaignFormPageState();
}

class _AdminCampaignFormPageState
    extends ConsumerState<AdminCampaignFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _urlController;

  File? _selectedImageFile;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateError;

  bool get _isEditing => widget.campaign != null;

  @override
  void initState() {
    super.initState();
    final campaign = widget.campaign;
    _titleController = TextEditingController(text: campaign?.title ?? '');
    _urlController = TextEditingController(text: campaign?.url ?? '');
    _startDate = _parseDay(campaign?.startDate);
    _endDate = _parseDay(campaign?.endDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // Web admin paneliyle AYNI gün formatı ("YYYY-MM-DD") — bkz.
  // `site/js/admin/admin.js`'deki `gunYaz`. `campaign_coupon.dart`'taki
  // `_parseCampaignDate` bunu ISO olarak tanıyor; başka bir biçim
  // (örn. nokta ayraçlı) yazılırsa geçerlilik hesapları bozulur.
  DateTime? _parseDay(final String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  String? _writeDay(final DateTime? date) {
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
    if (picked != null) setState(() => _selectedImageFile = File(picked.path));
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    setState(() => _dateError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(() => _dateError = 'Bitiş tarihi başlangıçtan önce olamaz.');
      return;
    }

    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    final startDate = _writeDay(_startDate) ?? '';
    final endDate = _writeDay(_endDate) ?? '';

    if (_isEditing) {
      final updatedData = <String, dynamic>{
        'title': title,
        'url': url,
        'startDate': startDate,
        'endDate': endDate,
      };
      await ref.read(campaignMutationProvider.notifier).updateCampaign(
            campaignId: widget.campaign!.id,
            updatedData: updatedData,
            imageFile: _selectedImageFile,
          );
    } else {
      final campaign = Campaign(
        id: '',
        createdAt: '',
        updatedAt: '',
        title: title,
        url: url,
        startDate: startDate,
        endDate: endDate,
        imageUrl: '',
      );
      await ref
          .read(campaignMutationProvider.notifier)
          .addCampaign(campaign, _selectedImageFile);
    }

    if (!mounted) return;
    final state = ref.read(campaignMutationProvider);
    if (state.hasError) {
      showDialog(
        context: context,
        builder: (final _) =>
            CustomErrorDialog(message: state.error.toString()),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final dialogContext) => CustomSuccessDialog(
          message:
              _isEditing ? 'Kampanya güncellendi.' : 'Kampanya oluşturuldu.',
          // Diyalog kendini kapatır; güncellemede sayfada kalınır, yeni
          // kayıtta admin listesine dönülür (bkz. AdminTeamFormPage).
          onConfirm: () {
            if (!_isEditing && mounted) Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final campaign = widget.campaign;
    if (campaign == null) return;
    await showDialog(
      context: context,
      builder: (final _) => CustomActionDialog(
        title: 'KAMPANYAYI SİL',
        message: '"${campaign.title}" kalıcı olarak silinecek. Emin misin?',
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        positiveText: 'SİL',
        negativeText: 'VAZGEÇ',
        onPositiveAction: () async {
          await ref
              .read(campaignMutationProvider.notifier)
              .deleteCampaign(campaign.id);
          if (!mounted) return;
          final state = ref.read(campaignMutationProvider);
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Silinemedi: ${state.error}'),
              backgroundColor: Colors.red,
            ));
          } else {
            Navigator.of(context).pop();
          }
        },
        onNegativeAction: () {},
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final isSaving = ref.watch(campaignMutationProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Kampanyayı Düzenle' : 'Yeni Kampanya'),
        actions: [
          if (_isEditing)
            Semantics(
              button: true,
              label: 'Kampanyayı sil',
              child: IconButton(
                tooltip: 'Sil',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: isSaving ? null : _confirmDelete,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminImagePickerField(
                  selectedFile: _selectedImageFile,
                  existingImageUrl: widget.campaign?.imageUrl,
                  onPick: _pickImage,
                  semanticLabel: 'Kampanya görseli, dokun ve değiştir',
                ),
                const AdminSectionTitle(
                    title: 'Kampanya Bilgileri', icon: Icons.local_offer_rounded),
                CustomTextField(controller: _titleController, label: 'Başlık'),
                CustomTextField(
                  controller: _urlController,
                  label: 'Bağlantı',
                  isRequired: false,
                  hintText: 'Kampanyaya tıklayınca açılacak adres',
                  keyboardType: TextInputType.url,
                ),
                const AdminSectionTitle(
                    title: 'Geçerlilik', icon: Icons.event_rounded),
                Row(
                  children: [
                    Expanded(
                      child: _DayPickerField(
                        label: 'Başlangıç',
                        value: _startDate,
                        onTap: isSaving ? null : _pickStartDate,
                        onClear: _startDate == null
                            ? null
                            : () => setState(() => _startDate = null),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _DayPickerField(
                        label: 'Bitiş',
                        value: _endDate,
                        onTap: isSaving ? null : _pickEndDate,
                        onClear: _endDate == null
                            ? null
                            : () => setState(() => _endDate = null),
                      ),
                    ),
                  ],
                ),
                if (_dateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(_dateError!,
                        style: TextStyle(color: context.colors.error, fontSize: 12)),
                  ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: _isEditing
                        ? 'Değişiklikleri kaydet'
                        : 'Kampanyayı oluştur',
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _save,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_isEditing ? 'Kaydet' : 'Kampanyayı Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gün seçici alan (saat yok) — Event formundaki tarih+saat seçiciyle AYNI
/// `showDatePicker` deseni, ama Campaign.startDate/endDate saat taşımaz.
/// İsteğe bağlı olduğu için seçili değerin temizlenebilmesi gerekir.
class _DayPickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _DayPickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final text = value == null
        ? 'Seçilmedi'
        : DateFormat('dd.MM.yyyy').format(value!);

    return Semantics(
      button: true,
      label: '$label, $text, dokun ve değiştir',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 11, color: colors.onSurfaceVariant)),
                    Text(text,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: value == null
                                ? colors.onSurfaceVariant
                                : colors.onSurface)),
                  ],
                ),
              ),
              if (onClear != null)
                Semantics(
                  button: true,
                  label: '$label tarihini temizle',
                  child: InkWell(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: colors.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
