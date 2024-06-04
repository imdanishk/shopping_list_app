import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/widgets/new_item.dart';
import '../data/categories.dart';
import '../models/grocery_item.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // Method to load items from the backend
  void _loadItems() async {
    // URL to fetch the grocery items from the Firebase database
    final url = Uri.https(
      'flutter-learning-shopping-list-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    try {
      // Send a GET request to the URL
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }

      // If the response body is 'null', it means no data is available
      // and dont execute code below of this
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Decode the response body from JSON
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      // Loop through the list data and create GroceryItem objects
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      // Update the state with the loaded items and set loading to false
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      // Handle any errors that occur during the request
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }


  // Method to navigate to the NewItemScreen and add a new item
  void _addItem() async {
    // Navigate to the NewItemScreen to get the new item details
    await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItemScreen(),
      ),
    );

    // Reload the items after adding a new one
    _loadItems();
  }


  // Method to remove an item from the backend and the local list
  void _removeItem(GroceryItem item) async {
    // Get the index of the item to be removed
    final index = _groceryItems.indexOf(item);
    setState(() {
      // Remove the item from the local list
      _groceryItems.remove(item);
    });

    // URL to delete the item from the Firebase database
    final url = Uri.https(
      'flutter-learning-shopping-list-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    // Send a DELETE request to the URL
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // Optional: Also can show error message
      // Reinsert the item back into the list if there was an error
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
