import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routinex/theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;
  String _verificationId = '';

  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _phoneFocusNode = FocusNode();

  String _countryCode = '+91';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _countryCodes = [
    (flag: '🇮🇳', code: '+91', name: 'India'),
    (flag: '🇺🇸', code: '+1',  name: 'USA'),
    (flag: '🇬🇧', code: '+44', name: 'UK'),
    (flag: '🇦🇺', code: '+61', name: 'Australia'),
    (flag: '🇨🇦', code: '+1',  name: 'Canada'),
    (flag: '🇸🇬', code: '+65', name: 'Singapore'),
    (flag: '🇦🇪', code: '+971',name: 'UAE'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  // ── Firebase: send OTP ──────────────────────────────────────
  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }

    setState(() { _loading = true; _errorMessage = null; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '$_countryCode$phone',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval on Android
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _loading = false;
          _errorMessage = e.message ?? 'Verification failed. Try again.';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _loading = false;
          _verificationId = verificationId;
          _otpSent = true;
        });
        // Animate in OTP screen
        _animController.reset();
        _animController.forward();
        Future.delayed(
          const Duration(milliseconds: 200),
          () => _otpFocusNodes[0].requestFocus(),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ── Firebase: verify OTP ────────────────────────────────────
  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    setState(() { _loading = true; _errorMessage = null; });

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: otp,
    );
    await _signInWithCredential(credential);
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      // AuthWrapper will navigate automatically via StreamBuilder
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.message ?? 'Invalid OTP. Please try again.';
      });
    }
  }

  // ── OTP box input handler ───────────────────────────────────
  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    // Auto-submit when all 6 filled
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) _verifyOTP();
  }

  // ── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _otpSent ? _buildOtpForm() : _buildPhoneForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo / brand
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text('RX', style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            )),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _otpSent ? 'Verify your\nnumber' : 'Welcome to\nRoutineX',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _otpSent
              ? 'Enter the 6-digit code sent to\n$_countryCode ${_phoneController.text.trim()}'
              : 'Track habits & expenses.\nSign in with your phone number.',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Phone input form ────────────────────────────────────────
  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country code picker
            GestureDetector(
              onTap: _showCountryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      _countryCodes
                          .firstWhere((c) => c.code == _countryCode,
                              orElse: () => _countryCodes.first)
                          .flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _countryCode,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Phone number field
            Expanded(
              child: TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
                decoration: InputDecoration(
                  hintText: '9876543210',
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                onSubmitted: (_) => _sendOTP(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) _errorBanner(),
        const SizedBox(height: 8),
        _primaryButton(
          label: 'Send OTP',
          icon: Icons.send_rounded,
          color: AppTheme.primary,
          onTap: _loading ? null : _sendOTP,
        ),
        const SizedBox(height: 24),
        _disclaimer(),
      ],
    );
  }

  // ── OTP input form ──────────────────────────────────────────
  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _otpBox(i)),
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) _errorBanner(),
        const SizedBox(height: 8),
        _primaryButton(
          label: 'Verify & Continue',
          icon: Icons.arrow_forward_rounded,
          color: AppTheme.secondary,
          onTap: _loading ? null : _verifyOTP,
        ),
        const SizedBox(height: 20),
        // Resend / change number row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _otpSent = false;
                  _errorMessage = null;
                  for (final c in _otpControllers) c.clear();
                });
                _animController.reset();
                _animController.forward();
              },
              child: const Text(
                '← Change number',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: _loading ? null : _sendOTP,
              child: const Text(
                'Resend OTP',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 46,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppTheme.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (v) => _onOtpChanged(v, index),
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────
  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onTap == null
                ? [color.withOpacity(0.4), color.withOpacity(0.3)]
                : [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return const Text(
      'By continuing, you agree to receive an SMS for verification. Standard rates may apply.',
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── Country picker bottom sheet ─────────────────────────────
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Country',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ..._countryCodes.map((c) => ListTile(
                  leading: Text(c.flag,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(c.name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                  trailing: Text(c.code,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                  onTap: () {
                    setState(() => _countryCode = c.code);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}