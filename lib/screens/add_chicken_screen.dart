import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/chicken.dart';

class AddChickenScreen extends StatefulWidget {
  final Chicken? chicken;

  const AddChickenScreen({super.key, this.chicken});

  @override
  State<AddChickenScreen> createState() => _AddChickenScreenState();
}

class _AddChickenScreenState extends State<AddChickenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _parentMaleController = TextEditingController();
  final _parentFemaleController = TextEditingController();
  final _healthNotesController = TextEditingController();

  DateTime _birthDate = DateTime.now();
  String _sex = 'Fêmea';
  String _status = 'Saudável';
  String? _photoPath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _sexOptions = ['Macho', 'Fêmea'];
  final List<String> _statusOptions = ['Saudável', 'Doente', 'Botando', 'Não Botando'];
  final List<String> _breedOptions = [
    'Leghorn',
    'Plymouth Rock',
    'Rhode Island Red',
    'Sussex',
    'Orpington',
    'Wyandotte',
    'Caipira',
    'Garnisé',
    'Outra',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.chicken != null) {
      _loadChickenData();
    }
  }

  void _loadChickenData() {
    final chicken = widget.chicken!;
    _nameController.text = chicken.name;
    _breedController.text = chicken.breed;
    _birthDate = chicken.birthDate;
    _sex = chicken.sex;
    _status = chicken.status;
    _photoPath = chicken.photoPath;
    _colorController.text = chicken.color ?? '';
    _parentMaleController.text = chicken.parentMale ?? '';
    _parentFemaleController.text = chicken.parentFemale ?? '';
    _healthNotesController.text = chicken.healthNotes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _parentMaleController.dispose();
    _parentFemaleController.dispose();
    _healthNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _photoPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveChicken() async {
    if (_formKey.currentState!.validate()) {
      try {
        final chicken = Chicken(
          id: widget.chicken?.id,
          name: _nameController.text,
          breed: _breedController.text,
          birthDate: _birthDate,
          photoPath: _photoPath,
          sex: _sex,
          color: _colorController.text.isEmpty ? null : _colorController.text,
          parentMale: _parentMaleController.text.isEmpty
              ? null
              : _parentMaleController.text,
          parentFemale: _parentFemaleController.text.isEmpty
              ? null
              : _parentFemaleController.text,
          healthNotes: _healthNotesController.text.isEmpty
              ? null
              : _healthNotesController.text,
          status: _status,
          createdAt: widget.chicken?.createdAt ?? DateTime.now(),
          updatedAt: widget.chicken != null ? DateTime.now() : null,
        );

        final appState = Provider.of<AppState>(context, listen: false);
        if (widget.chicken == null) {
          await appState.addChicken(chicken);
        } else {
          await appState.updateChicken(chicken);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.chicken == null
                    ? 'Galinha adicionada com sucesso!'
                    : 'Galinha atualizada com sucesso!',
              ),
            ),
          );
          _clearForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e')),
          );
        }
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _breedController.clear();
    _colorController.clear();
    _parentMaleController.clear();
    _parentFemaleController.clear();
    _healthNotesController.clear();
    setState(() {
      _birthDate = DateTime.now();
      _sex = 'Fêmea';
      _status = 'Saudável';
      _photoPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.chicken == null ? 'Adicionar Galinha' : 'Editar Galinha',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Nome',
                icon: Icons.pets,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildBreedDropdown(),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSexDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatusDropdown()),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _colorController,
                label: 'Cor',
                icon: Icons.palette,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _parentMaleController,
                label: 'Pai (opcional)',
                icon: Icons.male,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _parentFemaleController,
                label: 'Mãe (opcional)',
                icon: Icons.female,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _healthNotesController,
                label: 'Notas de Saúde',
                icon: Icons.medical_services,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChicken,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.lilacDark,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  widget.chicken == null ? 'ADICIONAR GALINHA' : 'SALVAR ALTERAÇÕES',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.chicken == null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _clearForm,
                  child: const Text('Limpar Formulário'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: AppTheme.rainbowGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _photoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_photoPath!),
                  fit: BoxFit.cover,
                ),
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 64, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Adicionar Foto',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.lilacDark),
      ),
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildBreedDropdown() {
    return DropdownButtonFormField<String>(
      value: _breedOptions.contains(_breedController.text)
          ? _breedController.text
          : null,
      decoration: const InputDecoration(
        labelText: 'Raça',
        prefixIcon: Icon(Icons.pets, color: AppTheme.lilacDark),
      ),
      items: _breedOptions.map((breed) {
        return DropdownMenuItem(
          value: breed,
          child: Text(breed),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _breedController.text = value;
        }
      },
      validator: (value) {
        if (_breedController.text.isEmpty) {
          return 'Por favor, selecione uma raça';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectBirthDate,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Data de Nascimento',
            prefixIcon: Icon(Icons.calendar_today, color: AppTheme.lilacDark),
          ),
          controller: TextEditingController(
            text: DateFormat('dd/MM/yyyy').format(_birthDate),
          ),
        ),
      ),
    );
  }

  Widget _buildSexDropdown() {
    return DropdownButtonFormField<String>(
      value: _sex,
      decoration: const InputDecoration(
        labelText: 'Sexo',
        prefixIcon: Icon(Icons.wc, color: AppTheme.lilacDark),
      ),
      items: _sexOptions.map((sex) {
        return DropdownMenuItem(
          value: sex,
          child: Text(sex),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _sex = value!;
        });
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.healing, color: AppTheme.lilacDark),
      ),
      items: _statusOptions.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _status = value!;
        });
      },
    );
  }
}
