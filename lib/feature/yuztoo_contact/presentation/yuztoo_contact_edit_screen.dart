import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/app_logo.dart';
import '../../../core/shared/widgets/back_button.dart';
import '../../../core/shared/widgets/yuztoo_tab_header.dart';
import '../../../core/utils/email_validator.dart' show EmailValidator;
import '../../storage/application/providers.dart' show uploadLogoProvider;
import '../application/providers.dart';
import '../domain/entities/restons_proches_profile.dart';

part 'yuztoo_contact_edit_screen.part.dart';

/// Owner-only editor for every field on the Restons proches page.
class YuztooContactEditScreen extends ConsumerStatefulWidget {
  const YuztooContactEditScreen({super.key, required this.initial});

  final RestonsProchesProfile initial;

  @override
  ConsumerState<YuztooContactEditScreen> createState() =>
      _YuztooContactEditScreenState();
}

class _YuztooContactEditScreenState
    extends ConsumerState<YuztooContactEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;

  String? _photoUrl;
  bool _saving = false;
  bool _uploadingPhoto = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _nameCtrl = TextEditingController(text: p.personName);
    _titleCtrl = TextEditingController(text: p.roleTitle);
    _bioCtrl = TextEditingController(text: p.bio);
    _phoneCtrl = TextEditingController(text: p.phone);
    _emailCtrl = TextEditingController(text: p.email);
    _addressCtrl = TextEditingController(text: p.address);
    _websiteCtrl = TextEditingController(text: p.website);
    _photoUrl = p.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildEditUi(context);
}
