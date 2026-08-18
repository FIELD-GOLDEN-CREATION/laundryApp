import 'form_field_spec.dart';

/// Every admin CRUD action (add/edit/reset/suspend/delete member, reassign
/// driver, refund order, contact client) opens the same generic form
/// modal — this is the per-kind copy the source's `modalCopy()` returns.
enum ModalKind { add, edit, reset, suspend, delete, reassign, refund, contact, changePassword }

class ModalCopy {
  const ModalCopy({required this.title, required this.sub, required this.primary, required this.fields});

  final String title;
  final String sub;
  final String primary;
  final List<FormFieldSpec> fields;
}

const kModalCopy = {
  ModalKind.add: ModalCopy(
    title: 'Add member',
    sub: 'Credentials are mandatory for every new account.',
    primary: 'Create account',
    fields: [
      FormFieldSpec(label: 'Full name', placeholder: 'e.g. Nadia Bello'),
      FormFieldSpec(label: 'Email', placeholder: 'name@gmail.com'),
      FormFieldSpec(label: 'Phone', placeholder: '+255 712 345 678'),
      FormFieldSpec(label: 'Password', placeholder: '••••••••', obscure: true),
    ],
  ),
  ModalKind.edit: ModalCopy(
    title: 'Edit member',
    sub: 'Update the account details on file.',
    primary: 'Save changes',
    fields: [
      FormFieldSpec(label: 'Full name', placeholder: 'Amara Reed'),
      FormFieldSpec(label: 'Email', placeholder: 'amara.reed@gmail.com'),
      FormFieldSpec(label: 'Phone', placeholder: '+255 754 220 441'),
    ],
  ),
  ModalKind.reset: ModalCopy(
    title: 'Reset password',
    sub: 'A temporary password is emailed to the member.',
    primary: 'Send reset link',
    fields: [
      FormFieldSpec(label: 'Email', placeholder: 'amara.reed@gmail.com'),
      FormFieldSpec(label: 'Temporary password', placeholder: '••••••••', obscure: true),
    ],
  ),
  ModalKind.suspend: ModalCopy(
    title: 'Suspend account',
    sub: 'The member keeps their history but cannot log in.',
    primary: 'Suspend',
    fields: [FormFieldSpec(label: 'Reason', placeholder: 'e.g. repeated cancellations')],
  ),
  ModalKind.delete: ModalCopy(
    title: 'Delete account',
    sub: 'This removes the member and all their data permanently.',
    primary: 'Delete permanently',
    fields: [FormFieldSpec(label: 'Type DELETE to confirm', placeholder: 'DELETE')],
  ),
  ModalKind.reassign: ModalCopy(
    title: 'Reassign driver',
    sub: 'Pick a driver currently online in this zone.',
    primary: 'Assign driver',
    fields: [FormFieldSpec(label: 'Driver', placeholder: 'Daniel Okafor · 1.2 km away')],
  ),
  ModalKind.refund: ModalCopy(
    title: 'Process refund',
    sub: 'Refunds are returned to the original payment method.',
    primary: 'Refund now',
    fields: [
      FormFieldSpec(label: 'Amount', placeholder: 'TZS 90,350'),
      FormFieldSpec(label: 'Reason', placeholder: 'e.g. damaged garment'),
    ],
  ),
  ModalKind.contact: ModalCopy(
    title: 'Contact client',
    sub: 'Send a message from the platform account.',
    primary: 'Send message',
    fields: [FormFieldSpec(label: 'Message', placeholder: 'Your order is on the way…')],
  ),
  ModalKind.changePassword: ModalCopy(
    title: 'Change password',
    sub: 'You will stay logged in on this device.',
    primary: 'Update password',
    fields: [
      FormFieldSpec(label: 'Current password', placeholder: '••••••••', obscure: true),
      FormFieldSpec(label: 'New password', placeholder: '••••••••', obscure: true),
      FormFieldSpec(label: 'Confirm new password', placeholder: '••••••••', obscure: true),
    ],
  ),
};
