class Orders {
  static const String $tableInfo = 'orders';
  static const String $createTableStatement = 'CREATE TABLE orders(id integer PRIMARY KEY AUTOINCREMENT, total decimal(5, 10) NOT NULL DEFAULT 0, customer_id int, customer_name varchar, customer_status varchar NOT NULL DEFAULT \'Hello there\'\'s\', date timestamp NOT NULL, dated timestamp NULL)';
  int id;
  double total;
  int? customerId;
  String? customerName;
  String customerStatus;
  DateTime date;
  DateTime? dated;

  Orders({
    required this.id,
    required this.total,
    this.customerId,
    this.customerName,
    required this.customerStatus,
    required this.date,
    this.dated,
  });

  factory Orders.fromJson(Map<String, dynamic> jsonMap) {
    return Orders(
      id: (jsonMap['id'] as num).toInt(),
      total: (jsonMap['total'] as num).toDouble(),
      customerId: (jsonMap['customer_id'] as num?)?.toInt(),
      customerName: jsonMap['customer_name'] as String?,
      customerStatus: jsonMap['customer_status'] as String,
      date: DateTime.parse(jsonMap['date']),
      dated: jsonMap['dated'] == null ? null : DateTime.parse(jsonMap['dated']),
    );
  }
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

  String toString() {
    return '''Orders(
  id: $id,
  total: $total,
  customerId: $customerId,
  customerName: $customerName,
  customerStatus: $customerStatus,
  date: $date,
  dated: $dated,
)''';  }

}
class Customers {
  static const String $tableInfo = 'customers';
  static const String $createTableStatement = 'CREATE TABLE customers(id integer PRIMARY KEY AUTOINCREMENT, name varchar NOT NULL DEFAULT NULL, status varchar NOT NULL DEFAULT \'\', updated_at timestamp NOT NULL DEFAULT CURRENT_DATE)';
  int id;
  String name;
  String status;
  DateTime updatedAt;

  Customers({
    required this.id,
    required this.name,
    required this.status,
    required this.updatedAt,
  });

  factory Customers.fromJson(Map<String, dynamic> jsonMap) {
    return Customers(
      id: (jsonMap['id'] as num).toInt(),
      name: jsonMap['name'] as String,
      status: jsonMap['status'] as String,
      updatedAt: DateTime.parse(jsonMap['updated_at']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String toString() {
    return '''Customers(
  id: $id,
  name: $name,
  status: $status,
  updatedAt: $updatedAt,
)''';  }

}
class Payments {
  static const String $tableInfo = 'payments';
  static const String $createTableStatement = 'CREATE TABLE payments(id int PRIMARY KEY, customer_id int NOT NULL, orders_id int NOT NULL, amount real NOT NULL)';
  int id;
  int customerId;
  int ordersId;
  double amount;

  Payments({
    required this.id,
    required this.customerId,
    required this.ordersId,
    required this.amount,
  });

  factory Payments.fromJson(Map<String, dynamic> jsonMap) {
    return Payments(
      id: (jsonMap['id'] as num).toInt(),
      customerId: (jsonMap['customer_id'] as num).toInt(),
      ordersId: (jsonMap['orders_id'] as num).toInt(),
      amount: (jsonMap['amount'] as num).toDouble(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'orders_id': ordersId,
      'amount': amount,
    };
  }

  String toString() {
    return '''Payments(
  id: $id,
  customerId: $customerId,
  ordersId: $ordersId,
  amount: $amount,
)''';  }

}
