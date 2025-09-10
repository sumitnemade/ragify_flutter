// MongoDB Test Data Setup Script
// This script creates sample data for testing RAGify Flutter with MongoDB

// Switch to test_db database
use('test_db');

// Create users collection with sample data
db.users.insertMany([
  {
    name: "John Doe",
    email: "john.doe@example.com",
    age: 30,
    department: "Engineering",
    salary: 75000,
    created_at: new Date()
  },
  {
    name: "Jane Smith",
    email: "jane.smith@example.com",
    age: 25,
    department: "Marketing",
    salary: 65000,
    created_at: new Date()
  },
  {
    name: "Bob Johnson",
    email: "bob.johnson@example.com",
    age: 35,
    department: "Sales",
    salary: 70000,
    created_at: new Date()
  },
  {
    name: "Alice Brown",
    email: "alice.brown@example.com",
    age: 28,
    department: "Engineering",
    salary: 80000,
    created_at: new Date()
  },
  {
    name: "Charlie Wilson",
    email: "charlie.wilson@example.com",
    age: 32,
    department: "HR",
    salary: 60000,
    created_at: new Date()
  },
  {
    name: "Diana Prince",
    email: "diana.prince@example.com",
    age: 29,
    department: "Marketing",
    salary: 68000,
    created_at: new Date()
  },
  {
    name: "Eve Adams",
    email: "eve.adams@example.com",
    age: 27,
    department: "Engineering",
    salary: 72000,
    created_at: new Date()
  },
  {
    name: "Frank Miller",
    email: "frank.miller@example.com",
    age: 33,
    department: "Sales",
    salary: 75000,
    created_at: new Date()
  }
]);

// Create products collection with sample data
db.products.insertMany([
  {
    name: "Laptop Pro",
    category: "Electronics",
    price: 1299.99,
    stock: 50,
    description: "High-performance laptop for professionals",
    created_at: new Date()
  },
  {
    name: "Wireless Mouse",
    category: "Electronics",
    price: 29.99,
    stock: 200,
    description: "Ergonomic wireless mouse",
    created_at: new Date()
  },
  {
    name: "Office Chair",
    category: "Furniture",
    price: 299.99,
    stock: 30,
    description: "Comfortable ergonomic office chair",
    created_at: new Date()
  },
  {
    name: "Standing Desk",
    category: "Furniture",
    price: 599.99,
    stock: 15,
    description: "Adjustable height standing desk",
    created_at: new Date()
  },
  {
    name: "Coffee Maker",
    category: "Appliances",
    price: 89.99,
    stock: 40,
    description: "Programmable coffee maker",
    created_at: new Date()
  },
  {
    name: "Monitor 27\"",
    category: "Electronics",
    price: 399.99,
    stock: 25,
    description: "4K Ultra HD monitor",
    created_at: new Date()
  },
  {
    name: "Desk Lamp",
    category: "Furniture",
    price: 49.99,
    stock: 60,
    description: "LED desk lamp with adjustable brightness",
    created_at: new Date()
  },
  {
    name: "Bluetooth Speaker",
    category: "Electronics",
    price: 79.99,
    stock: 35,
    description: "Portable Bluetooth speaker",
    created_at: new Date()
  }
]);

// Create orders collection with sample data
db.orders.insertMany([
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 2,
    total_amount: 2599.98,
    status: "completed",
    order_date: new Date(),
    shipping_address: "123 Main St, City, State 12345"
  },
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 1,
    total_amount: 29.99,
    status: "pending",
    order_date: new Date(),
    shipping_address: "456 Oak Ave, City, State 12345"
  },
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 1,
    total_amount: 299.99,
    status: "completed",
    order_date: new Date(),
    shipping_address: "789 Pine Rd, City, State 12345"
  },
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 1,
    total_amount: 599.99,
    status: "shipped",
    order_date: new Date(),
    shipping_address: "321 Elm St, City, State 12345"
  },
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 3,
    total_amount: 269.97,
    status: "completed",
    order_date: new Date(),
    shipping_address: "654 Maple Dr, City, State 12345"
  },
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 1,
    total_amount: 399.99,
    status: "pending",
    order_date: new Date(),
    shipping_address: "987 Cedar Ln, City, State 12345"
  },
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 2,
    total_amount: 99.98,
    status: "completed",
    order_date: new Date(),
    shipping_address: "147 Birch St, City, State 12345"
  },
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 1,
    total_amount: 79.99,
    status: "shipped",
    order_date: new Date(),
    shipping_address: "258 Spruce Ave, City, State 12345"
  },
  {
    user_id: ObjectId(),
    product_id: ObjectId(),
    quantity: 1,
    total_amount: 89.99,
    status: "completed",
    order_date: new Date(),
    shipping_address: "369 Willow Rd, City, State 12345"
  }
]);

// Create indexes for better performance
db.users.createIndex({ "name": "text", "email": "text" });
db.users.createIndex({ "department": 1 });
db.users.createIndex({ "age": 1 });

db.products.createIndex({ "name": "text", "description": "text" });
db.products.createIndex({ "category": 1 });
db.products.createIndex({ "price": 1 });

db.orders.createIndex({ "status": 1 });
db.orders.createIndex({ "order_date": 1 });
db.orders.createIndex({ "user_id": 1 });

print("✅ MongoDB test data setup completed successfully!");
print("📊 Created collections: users, products, orders");
print("📈 Users: " + db.users.countDocuments() + " documents");
print("📈 Products: " + db.products.countDocuments() + " documents");
print("📈 Orders: " + db.orders.countDocuments() + " documents");
