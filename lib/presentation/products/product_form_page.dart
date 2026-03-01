import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/supabase_storage_service.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/datasources/section_remote_datasource.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/section.dart';
import '../../domain/repositories/product_repository.dart';

/// Formulário de criação/edição de produto. Inclui seleção de imagens (galeria/câmera) e upload para Supabase Storage.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, required ProductRepository productRepository, this.product})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = SupabaseStorageService();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  bool _active = true;
  bool _loading = false;
  String? _error;
  final List<XFile> _selectedFiles = [];
  late List<String> _existingImageUrls;
  final _categoriesDatasource = CategoryRemoteDatasource();
  List<Category> _allCategories = [];
  late Set<String> _selectedCategoryIds;
  final _sectionsDatasource = SectionRemoteDatasource();
  List<Section> _allSections = [];
  late Set<String> _selectedSectionIds;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _existingImageUrls = List.from(p?.images ?? []);
    _selectedCategoryIds = Set.from(p?.categories?.map((c) => c.id) ?? []);
    _selectedSectionIds = Set.from(p?.sections?.map((s) => s.id) ?? []);
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toStringAsFixed(2) : '');
    _stockController = TextEditingController(text: p?.stock.toString() ?? '0');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _active = p?.active ?? true;
    _loadCategories();
    _loadSections();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _categoriesDatasource.getCategories();
      if (mounted) setState(() => _allCategories = list);
    } catch (_) {}
  }

  Future<void> _loadSections() async {
    try {
      final list = await _sectionsDatasource.getSections();
      if (mounted) setState(() => _allSections = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _pickGallery() async {
    try {
      final list = await _picker.pickMultiImage();
      if (!mounted) return;
      setState(() => _selectedFiles.addAll(list));
    } catch (_) {}
  }

  Future<void> _pickCamera() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        setState(() => _selectedFiles.add(photo));
      }
    } catch (_) {}
  }

  void _removeSelectedAt(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  Future<void> _removeExistingImage(int index) async {
    if (!widget.isEditing || widget.product == null) return;
    final url = _existingImageUrls[index];
    setState(() => _loading = true);
    try {
      final deleted = await _storage.deleteProductImageByUrl(url);
      if (!mounted) return;
      if (deleted) {
        setState(() => _existingImageUrls.removeAt(index));
        await widget._productRepository.updateProduct(
          widget.product!.id,
          images: List.from(_existingImageUrls),
        );
      } else {
        setState(() => _error = 'Não foi possível remover a imagem do servidor.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
      final stock = int.tryParse(_stockController.text) ?? 0;
      final sku = _skuController.text.trim().isEmpty ? null : _skuController.text.trim();

      List<String> imageUrls = List.from(_existingImageUrls);

      if (widget.isEditing && widget.product != null) {
        await widget._productRepository.updateProduct(
          widget.product!.id,
          name: name,
          description: description.isEmpty ? null : description,
          price: price,
          stock: stock,
          sku: sku,
          active: _active,
          categoryIds: _selectedCategoryIds.toList(),
          sectionIds: _selectedSectionIds.toList(),
        );
        if (_storage.isAvailable && _selectedFiles.isNotEmpty) {
          for (final file in _selectedFiles) {
            final url = await _storage.uploadProductImage(widget.product!.id, file);
            if (url != null) imageUrls.add(url);
          }
          if (imageUrls.isNotEmpty) {
            await widget._productRepository.updateProduct(widget.product!.id, images: imageUrls);
          }
        }
      } else {
        Product product = await widget._productRepository.createProduct(
          name: name,
          description: description.isEmpty ? null : description,
          price: price,
          stock: stock,
          sku: sku,
          active: _active,
          categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.toList(),
          sectionIds: _selectedSectionIds.isEmpty ? null : _selectedSectionIds.toList(),
        );
        if (_storage.isAvailable && _selectedFiles.isNotEmpty) {
          for (final file in _selectedFiles) {
            final url = await _storage.uploadProductImage(product.id, file);
            if (url != null) imageUrls.add(url);
          }
          if (imageUrls.isNotEmpty) {
            await widget._productRepository.updateProduct(product.id, images: imageUrls);
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStorage = _storage.isAvailable;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Editar produto' : 'Novo produto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obrigatório';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Estoque *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Número válido (≥ 0)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Ativo'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 24),
              const Text('Categorias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allCategories.map((cat) {
                  final selected = _selectedCategoryIds.contains(cat.id);
                  return FilterChip(
                    label: Text(cat.name),
                    selected: selected,
                    onSelected: _loading
                        ? null
                        : (v) {
                            setState(() {
                              if (v) {
                                _selectedCategoryIds.add(cat.id);
                              } else {
                                _selectedCategoryIds.remove(cat.id);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Seções', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSections.map((sec) {
                  final selected = _selectedSectionIds.contains(sec.id);
                  return FilterChip(
                    label: Text(sec.name),
                    selected: selected,
                    onSelected: _loading
                        ? null
                        : (v) {
                            setState(() {
                              if (v) {
                                _selectedSectionIds.add(sec.id);
                              } else {
                                _selectedSectionIds.remove(sec.id);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Imagens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (!hasStorage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Configure SUPABASE_URL e SUPABASE_ANON_KEY para enviar imagens.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              if (_existingImageUrls.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_existingImageUrls.length, (i) {
                    final url = _existingImageUrls[i];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Icon(Icons.broken_image),
                                ),
                          ),
                        ),
                        if (widget.isEditing)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: _loading ? null : () => _removeExistingImage(i),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                                padding: const EdgeInsets.all(4),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 8),
              ],
              if (_selectedFiles.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_selectedFiles.length, (i) {
                    return Stack(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: const Icon(Icons.image, size: 48),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => _removeSelectedAt(i),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              const SizedBox(height: 8),
              if (hasStorage)
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _loading ? null : _pickGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _loading ? null : _pickCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Câmera'),
                    ),
                  ],
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child:
                    _loading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(widget.isEditing ? 'Salvar' : 'Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
