class Orders {
  Orders({
    required this.id,
    required this.total,
    this.customerId,
    this.customerName,
    required this.customerStatus,
    required this.date,
    this.dated,
  });

  factory Orders.fromJson(Map<String, dynamic> data) => Orders(
    id: (data['id'] as num).toInt(),
    total: (data['total'] as num).toDouble(),
    customerId: (data['customer_id'] as num?)?.toInt(),
    customerName: data['customer_name'] as String?,
    customerStatus: data['customer_status'] as String,
    date: DateTime.parse(data['date']),
    dated: data['dated'] == null ? null : DateTime.parse(data['dated']),
  );

  static const String $tableName = 'orders';

  static const String $createTableStatement =
      'CREATE TABLE orders(id integer PRIMARY KEY AUTOINCREMENT, total decimal(5, 10) NOT NULL DEFAULT 0, customer_id int, customer_name varchar, customer_status varchar NOT NULL DEFAULT \'Hello there\'\'s\', date timestamp NOT NULL, dated timestamp NULL)';

  final int id;

  final double total;

  final int? customerId;

  final String? customerName;

  final String customerStatus;

  final DateTime date;

  final DateTime? dated;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total': total,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_status': customerStatus,
      'date': date.toIso8601String(),
      'dated': dated?.toIso8601String(),
    };
  }
}

class Customers {
  Customers({
    required this.id,
    required this.name,
    required this.status,
    required this.updatedAt,
  });

  factory Customers.fromJson(Map<String, dynamic> data) => Customers(
    id: (data['id'] as num).toInt(),
    name: data['name'] as String,
    status: data['status'] as String,
    updatedAt: DateTime.parse(data['updated_at']),
  );

  static const String $tableName = 'customers';

  static const String $createTableStatement =
      'CREATE TABLE customers(id integer PRIMARY KEY AUTOINCREMENT, name varchar NOT NULL DEFAULT NULL, status varchar NOT NULL DEFAULT \'\', updated_at timestamp NOT NULL DEFAULT CURRENT_DATE)';

  final int id;

  final String name;

  final String status;

  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Payments {
  Payments({
    required this.id,
    required this.customerId,
    required this.ordersId,
    required this.amount,
  });

  factory Payments.fromJson(Map<String, dynamic> data) => Payments(
    id: (data['id'] as num).toInt(),
    customerId: (data['customer_id'] as num).toInt(),
    ordersId: (data['orders_id'] as num).toInt(),
    amount: (data['amount'] as num).toDouble(),
  );

  static const String $tableName = 'payments';

  static const String $createTableStatement =
      'CREATE TABLE payments(id int PRIMARY KEY, customer_id int NOT NULL, orders_id int NOT NULL, amount real NOT NULL)';

  final int id;

  final int customerId;

  final int ordersId;

  final double amount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'orders_id': ordersId,
      'amount': amount,
    };
  }
}
