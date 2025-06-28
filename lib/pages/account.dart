import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:skincare/page.dart';
import 'package:skincare/services/product_database.dart';

class AccountPage extends AppPage {
  const AccountPage({super.key});
  @override
  String get title => 'Account';

  Future<void> exportAccountData(BuildContext context) async {
    // Implement export logic here
    // This could involve saving user data to a file or sending it to a server
    // For now, we will just show a placeholder message
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting account data...')));
    final filePath = await ProductDatabase.instance.exportDatabase();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account data exported to $filePath')),
    );
  }

  Future<void> importAccountData(BuildContext context) async {
    // Open file picker to select a file
    print("test");
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ["json"],
      );

      // if no file is picked
      if (result == null) return;

      final filePath = result.files.single.path;
      await ProductDatabase.instance.importDatabase(filePath!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account data imported from $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing account data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Export Account Data'),
          onTap: () => exportAccountData(context),
        ),
        ListTile(
          title: const Text('Import Account Data'),
          onTap: () => importAccountData(context),
        ),
      ],
    );
  }
}
