import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/payment_service.dart';

enum _PayMethod { card, upi, cash }

enum _PayState { idle, loading, success, failure }

Future<bool> showPaymentSheet(
  BuildContext context, {
  required String orderId,
  required String paymentId,
  required String paymentIntentId,
  required num amount,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(
      orderId: orderId,
      paymentId: paymentId,
      paymentIntentId: paymentIntentId,
      amount: amount,
    ),
  );
  return result ?? false;
}

class _PaymentSheet extends StatefulWidget {
  final String orderId;
  final String paymentId;
  final String paymentIntentId;
  final num amount;

  _PaymentSheet({
    required this.orderId,
    required this.paymentId,
    required this.paymentIntentId,
    required this.amount,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet>
    with SingleTickerProviderStateMixin {
  _PayMethod _method = _PayMethod.card;
  _PayState _state = _PayState.idle;
  final PaymentService _paymentService = PaymentService();

  // Card form controllers
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // UPI ID
  final _upiCtrl = TextEditingController();

  late final AnimationController _successController;
  late final Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _successAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    _upiCtrl.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _state = _PayState.loading);
    try {
      if (_method == _PayMethod.cash) {
        await _paymentService.confirmCashPayment(
          paymentId: widget.paymentId,
          orderId: widget.orderId,
        );
      } else {
        // For Card / UPI — use the same confirm endpoint with the mock/real paymentIntentId
        await _paymentService.confirmPayment(
          paymentIntentId: widget.paymentIntentId,
          paymentId: widget.paymentId,
          orderId: widget.orderId,
        );
      }
      setState(() => _state = _PayState.success);
      _successController.forward();
      await Future.delayed(Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _state = _PayState.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),

          if (_state == _PayState.success)
            _buildSuccess()
          else if (_state == _PayState.failure)
            _buildFailure()
          else ...[
            _buildHeader(),
            SizedBox(height: 20),
            _buildMethodTabs(),
            SizedBox(height: 20),
            _buildMethodContent(),
            SizedBox(height: 24),
            _buildPayButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.lock_rounded, color: AppColors.brandGreen, size: 20),
        SizedBox(width: 8),
        Text(
          'Secure Payment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '₹${widget.amount}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.brandBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTabs() {
    final methods = [
      {'method': _PayMethod.card, 'icon': Icons.credit_card_rounded, 'label': 'Card'},
      {'method': _PayMethod.upi, 'icon': Icons.qr_code_rounded, 'label': 'UPI'},
      {'method': _PayMethod.cash, 'icon': Icons.money_rounded, 'label': 'Cash'},
    ];

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: methods.map((m) {
          final selected = _method == m['method'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _method = m['method'] as _PayMethod),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.brandBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      m['icon'] as IconData,
                      color: selected ? Colors.white : AppColors.textMuted,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      m['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMethodContent() {
    switch (_method) {
      case _PayMethod.card:
        return _buildCardForm();
      case _PayMethod.upi:
        return _buildUpiForm();
      case _PayMethod.cash:
        return _buildCashForm();
    }
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        // Animated card display
        Container(
          height: 100,
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), AppColors.brandBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    ValueListenableBuilder(
                      valueListenable: _cardNumberCtrl,
                      builder: (_, val, __) {
                        final num = val.text.isEmpty
                            ? '•••• •••• •••• ••••'
                            : val.text;
                        return Text(
                          num,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('VALID THRU',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 8)),
                  ValueListenableBuilder(
                    valueListenable: _expiryCtrl,
                    builder: (_, val, __) => Text(
                      val.text.isEmpty ? '••/••' : val.text,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        _inputField(
          controller: _cardNumberCtrl,
          label: 'Card Number',
          hint: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          maxLength: 19,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _inputField(
                controller: _expiryCtrl,
                label: 'Expiry',
                hint: 'MM/YY',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryFormatter(),
                ],
                maxLength: 5,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _inputField(
                controller: _cvvCtrl,
                label: 'CVV',
                hint: '•••',
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 3,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _inputField(
          controller: _nameCtrl,
          label: 'Name on Card',
          hint: 'Your full name',
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }

  Widget _buildUpiForm() {
    var upiId = 'fixngo@upi';
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            children: [
              // Fake QR with grid pattern
              Container(
                width: 160,
                height: 160,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.count(
                  crossAxisCount: 7,
                  physics: NeverScrollableScrollPhysics(),
                  children: List.generate(49, (i) {
                    final filledCells = {
                      0,1,2,3,4,5,6,7,13,14,20,21,22,23,24,25,26,27,28,34,35,
                      41,42,43,44,45,46,47,48,10,11,12,36,37,38
                    };
                    return Container(
                      margin: EdgeInsets.all(1),
                      color: filledCells.contains(i)
                          ? Colors.black
                          : Colors.white,
                    );
                  }),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Scan to Pay',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    upiId,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: upiId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('UPI ID copied!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR enter UPI ID',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textMuted)),
            ),
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
        SizedBox(height: 12),
        _inputField(
          controller: _upiCtrl,
          label: 'Your UPI ID',
          hint: 'yourname@upi',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildCashForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.money_rounded, color: AppColors.brandGreen, size: 36),
          ),
          SizedBox(height: 16),
          Text(
            'Pay ₹${widget.amount} to technician',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please keep exact change ready. The technician will collect cash after completing the repair.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: GoogleFonts.poppins(
              color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                color: AppColors.textMuted, fontSize: 14),
            counterText: '',
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    String label;
    Color color;
    switch (_method) {
      case _PayMethod.card:
        label = 'Pay ₹${widget.amount} with Card';
        color = AppColors.brandBlue;
        break;
      case _PayMethod.upi:
        label = 'Pay ₹${widget.amount} via UPI';
        color = Color(0xFF6C47FF);
        break;
      case _PayMethod.cash:
        label = 'Confirm Cash Payment';
        color = AppColors.brandGreen;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: _state == _PayState.loading ? null : _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _state == _PayState.loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        SizedBox(height: 16),
        ScaleTransition(
          scale: _successAnim,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: AppColors.brandGreen, size: 44),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Payment Successful!',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '₹${widget.amount} paid successfully',
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFailure() {
    return Column(
      children: [
        SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.statusRed.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close_rounded, color: AppColors.statusRed, size: 44),
        ),
        SizedBox(height: 20),
        Text(
          'Payment Failed',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please try again or use a different method.',
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() => _state = _PayState.idle),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Try Again',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

// ─── Input Formatters ─────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (text.length == 2 && oldValue.text.length == 1) {
      text = '$text/';
    }
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
