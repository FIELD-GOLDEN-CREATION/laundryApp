class FormFieldSpec {
  const FormFieldSpec({required this.label, required this.placeholder, this.obscure = false});

  final String label;
  final String placeholder;
  final bool obscure;
}
