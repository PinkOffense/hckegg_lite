import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/vaccine.dart';
import '../models/chicken.dart';

class VaccinesScreen extends StatefulWidget {
  const VaccinesScreen({super.key});

  @override
  State<VaccinesScreen> createState() => _VaccinesScreenState();
}

class _VaccinesScreenState extends State<VaccinesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Vacinas e Relatórios',
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Relatório',
            onPressed: () => _showExportDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.rainbowGradient,
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Vacinas'),
                Tab(text: 'Calendário'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVaccinesTab(),
                _buildCalendarTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: GradientFAB(
        icon: Icons.add,
        tooltip: 'Adicionar Vacina',
        onPressed: () => _showAddVaccineDialog(context),
      ),
    );
  }

  Widget _buildVaccinesTab() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appState.vaccines.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => appState.loadVaccines(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: appState.vaccines.length,
            itemBuilder: (context, index) {
              final vaccine = appState.vaccines[index];
              final chicken = vaccine.chickenId != null
                  ? appState.chickens.firstWhere(
                      (c) => c.id == vaccine.chickenId,
                      orElse: () => Chicken(
                        name: 'Desconhecida',
                        breed: '',
                        birthDate: DateTime.now(),
                        sex: 'Fêmea',
                      ),
                    )
                  : null;
              return _buildVaccineCard(vaccine, chicken, appState);
            },
          ),
        );
      },
    );
  }

  Widget _buildCalendarTab() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final dueVaccines = appState.vaccines
            .where((v) => v.nextDueDate != null)
            .toList()
          ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));

        if (dueVaccines.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 100, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma vacina agendada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: dueVaccines.length,
          itemBuilder: (context, index) {
            final vaccine = dueVaccines[index];
            final chicken = vaccine.chickenId != null
                ? appState.chickens.firstWhere(
                    (c) => c.id == vaccine.chickenId,
                    orElse: () => Chicken(
                      name: 'Desconhecida',
                      breed: '',
                      birthDate: DateTime.now(),
                      sex: 'Fêmea',
                    ),
                  )
                : null;
            return _buildCalendarCard(vaccine, chicken);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 100, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma vacina registrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Registre a primeira vacina!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineCard(
      Vaccine vaccine, Chicken? chicken, AppState appState) {
    return GradientCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: vaccine.isDue
              ? Colors.red
              : vaccine.isDueSoon
                  ? Colors.orange
                  : AppTheme.blueLight,
          child: Icon(
            vaccine.isDue
                ? Icons.warning
                : vaccine.isDueSoon
                    ? Icons.schedule
                    : Icons.check,
            color: Colors.white,
          ),
        ),
        title: Text(
          vaccine.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chicken != null) Text('Galinha: ${chicken.name}'),
            if (chicken == null) const Text('Aplicado em todo o plantel'),
            Text(
                'Aplicado: ${DateFormat('dd/MM/yyyy').format(vaccine.vaccinationDate)}'),
            if (vaccine.nextDueDate != null)
              Text(
                'Próxima: ${DateFormat('dd/MM/yyyy').format(vaccine.nextDueDate!)}',
                style: TextStyle(
                  color: vaccine.isDue
                      ? Colors.red
                      : vaccine.isDueSoon
                          ? Colors.orange
                          : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              _confirmDelete(vaccine, appState);
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

  Widget _buildCalendarCard(Vaccine vaccine, Chicken? chicken) {
    return GradientCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: vaccine.isDue
              ? Colors.red
              : vaccine.isDueSoon
                  ? Colors.orange
                  : Colors.green,
          child: Text(
            '${vaccine.nextDueDate!.day}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          vaccine.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chicken != null) Text('Galinha: ${chicken.name}'),
            Text(
              DateFormat('MMMM yyyy', 'pt_BR').format(vaccine.nextDueDate!),
            ),
            if (vaccine.isDue)
              const Text(
                'ATRASADA',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (vaccine.isDueSoon)
              Text(
                'Em ${vaccine.daysUntilDue} dias',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                'Em ${vaccine.daysUntilDue} dias',
                style: const TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddVaccineDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => _AddVaccineDialog(chickens: appState.chickens),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Relatório'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppTheme.blueLight),
              title: const Text('Exportar CSV - Galinhas'),
              onTap: () {
                Navigator.pop(context);
                _exportChickensCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.egg, color: AppTheme.pinkLight),
              title: const Text('Exportar CSV - Ovos'),
              onTap: () {
                Navigator.pop(context);
                _exportEggsCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: AppTheme.lilacLight),
              title: const Text('Exportar CSV - Vacinas'),
              onTap: () {
                Navigator.pop(context);
                _exportVaccinesCSV();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportChickensCSV() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final chickens = appState.chickens;

      List<List<dynamic>> rows = [
        ['Nome', 'Raça', 'Data Nascimento', 'Sexo', 'Status', 'Cor', 'Idade']
      ];

      for (var chicken in chickens) {
        rows.add([
          chicken.name,
          chicken.breed,
          DateFormat('dd/MM/yyyy').format(chicken.birthDate),
          chicken.sex,
          chicken.status,
          chicken.color ?? '',
          chicken.formattedAge,
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/galinhas_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exportado: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  Future<void> _exportEggsCSV() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final eggs = appState.eggs;

      List<List<dynamic>> rows = [
        ['Galinha ID', 'Data Postura', 'Quantidade', 'Choca', 'Notas']
      ];

      for (var egg in eggs) {
        rows.add([
          egg.chickenId,
          DateFormat('dd/MM/yyyy').format(egg.layDate),
          egg.quantity,
          egg.isClutch ? 'Sim' : 'Não',
          egg.notes ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/ovos_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exportado: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  Future<void> _exportVaccinesCSV() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final vaccines = appState.vaccines;

      List<List<dynamic>> rows = [
        ['Nome', 'Galinha ID', 'Data Aplicação', 'Próxima Data', 'Aplicado Por']
      ];

      for (var vaccine in vaccines) {
        rows.add([
          vaccine.name,
          vaccine.chickenId?.toString() ?? 'Todos',
          DateFormat('dd/MM/yyyy').format(vaccine.vaccinationDate),
          vaccine.nextDueDate != null
              ? DateFormat('dd/MM/yyyy').format(vaccine.nextDueDate!)
              : '',
          vaccine.administeredBy ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/vacinas_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exportado: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  void _confirmDelete(Vaccine vaccine, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a vacina ${vaccine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await appState.deleteVaccine(vaccine.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vacina excluída com sucesso!')),
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

class _AddVaccineDialog extends StatefulWidget {
  final List<Chicken> chickens;

  const _AddVaccineDialog({required this.chickens});

  @override
  State<_AddVaccineDialog> createState() => _AddVaccineDialogState();
}

class _AddVaccineDialogState extends State<_AddVaccineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _administeredByController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedChickenId;
  DateTime _vaccinationDate = DateTime.now();
  DateTime? _nextDueDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _administeredByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isVaccinationDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isVaccinationDate
          ? _vaccinationDate
          : (_nextDueDate ?? DateTime.now().add(const Duration(days: 90))),
      firstDate: isVaccinationDate
          ? DateTime.now().subtract(const Duration(days: 365))
          : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null) {
      setState(() {
        if (isVaccinationDate) {
          _vaccinationDate = picked;
        } else {
          _nextDueDate = picked;
        }
      });
    }
  }

  Future<void> _saveVaccine() async {
    if (_formKey.currentState!.validate()) {
      try {
        final vaccine = Vaccine(
          chickenId: _selectedChickenId,
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          vaccinationDate: _vaccinationDate,
          nextDueDate: _nextDueDate,
          administeredBy: _administeredByController.text.isEmpty
              ? null
              : _administeredByController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        final appState = Provider.of<AppState>(context, listen: false);
        await appState.addVaccine(vaccine);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vacina registrada com sucesso!')),
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
      title: const Text('Adicionar Vacina'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Vacina',
                  prefixIcon: Icon(Icons.medical_services, color: AppTheme.lilacDark),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome da vacina';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _selectedChickenId,
                decoration: const InputDecoration(
                  labelText: 'Galinha (opcional)',
                  prefixIcon: Icon(Icons.pets, color: AppTheme.lilacDark),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todo o plantel'),
                  ),
                  ...widget.chickens.map((chicken) {
                    return DropdownMenuItem(
                      value: chicken.id!,
                      child: Text(chicken.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedChickenId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(true),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data de Aplicação',
                      prefixIcon:
                          Icon(Icons.calendar_today, color: AppTheme.lilacDark),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(_vaccinationDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(false),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Próxima Dose (opcional)',
                      prefixIcon: Icon(Icons.event, color: AppTheme.lilacDark),
                    ),
                    controller: TextEditingController(
                      text: _nextDueDate != null
                          ? DateFormat('dd/MM/yyyy').format(_nextDueDate!)
                          : '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _administeredByController,
                decoration: const InputDecoration(
                  labelText: 'Aplicado por (opcional)',
                  prefixIcon: Icon(Icons.person, color: AppTheme.lilacDark),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  prefixIcon: Icon(Icons.description, color: AppTheme.lilacDark),
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
          onPressed: _saveVaccine,
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
