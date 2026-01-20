import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/egg.dart';
import '../models/chicken.dart';

class EggProductionScreen extends StatefulWidget {
  const EggProductionScreen({super.key});

  @override
  State<EggProductionScreen> createState() => _EggProductionScreenState();
}

class _EggProductionScreenState extends State<EggProductionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Produção de Ovos',
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.eggs.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => appState.loadEggs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: appState.eggs.length,
              itemBuilder: (context, index) {
                final egg = appState.eggs[index];
                final chicken = appState.chickens
                    .firstWhere((c) => c.id == egg.chickenId,
                        orElse: () => Chicken(
                              name: 'Desconhecida',
                              breed: '',
                              birthDate: DateTime.now(),
                              sex: 'Fêmea',
                            ));
                return _buildEggCard(egg, chicken, appState);
              },
            ),
          );
        },
      ),
      floatingActionButton: GradientFAB(
        icon: Icons.add,
        tooltip: 'Adicionar Registro de Ovo',
        onPressed: () => _showAddEggDialog(context),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.egg_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhum ovo registrado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registre o primeiro ovo!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEggCard(Egg egg, Chicken chicken, AppState appState) {
    return GradientCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: egg.isClutch ? AppTheme.pinkDark : AppTheme.blueLight,
          child: Icon(
            egg.isClutch ? Icons.egg : Icons.egg_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          chicken.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(egg.layDate)}',
            ),
            Text('Quantidade: ${egg.quantity}'),
            if (egg.isClutch)
              Text(
                'Choca - ${egg.daysUntilHatch > 0 ? "${egg.daysUntilHatch} dias até eclosão" : "Eclodindo!"}',
                style: TextStyle(
                  color: egg.isHatching ? Colors.orange : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (egg.notes != null) Text('Nota: ${egg.notes}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              _confirmDelete(egg, appState);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEggDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final hens = appState.chickens.where((c) => c.sex == 'Fêmea').toList();

    if (hens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione uma galinha fêmea primeiro!'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddEggDialog(hens: hens),
    );
  }

  void _confirmDelete(Egg egg, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir este registro de ovo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await appState.deleteEgg(egg.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registro excluído com sucesso!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _AddEggDialog extends StatefulWidget {
  final List<Chicken> hens;

  const _AddEggDialog({required this.hens});

  @override
  State<_AddEggDialog> createState() => _AddEggDialogState();
}

class _AddEggDialogState extends State<_AddEggDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _selectedChickenId;
  DateTime _layDate = DateTime.now();
  int _quantity = 1;
  bool _isClutch = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedChickenId = widget.hens.first.id!;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectLayDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _layDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _layDate) {
      setState(() {
        _layDate = picked;
      });
    }
  }

  Future<void> _saveEgg() async {
    if (_formKey.currentState!.validate()) {
      try {
        final egg = Egg(
          chickenId: _selectedChickenId,
          layDate: _layDate,
          quantity: _quantity,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          isClutch: _isClutch,
        );

        final appState = Provider.of<AppState>(context, listen: false);
        await appState.addEgg(egg);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ovo registrado com sucesso!')),
          );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Registro de Ovo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedChickenId,
                decoration: const InputDecoration(
                  labelText: 'Galinha',
                  prefixIcon: Icon(Icons.pets, color: AppTheme.lilacDark),
                ),
                items: widget.hens.map((hen) {
                  return DropdownMenuItem(
                    value: hen.id!,
                    child: Text(hen.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedChickenId = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectLayDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data da Postura',
                      prefixIcon: Icon(Icons.calendar_today, color: AppTheme.lilacDark),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(_layDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  prefixIcon: Icon(Icons.numbers, color: AppTheme.lilacDark),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _quantity = int.tryParse(value) ?? 1;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a quantidade';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Quantidade deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('É choca?'),
                subtitle: const Text('Para incubação'),
                value: _isClutch,
                onChanged: (value) {
                  setState(() {
                    _isClutch = value;
                  });
                },
                activeColor: AppTheme.pinkDark,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note, color: AppTheme.lilacDark),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveEgg,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lilacDark,
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
