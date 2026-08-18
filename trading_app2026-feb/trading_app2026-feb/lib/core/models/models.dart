// models.dart
import 'package:flutter/material.dart';

enum TransactionType { buy, sell }

enum HoldingType { stock, crypto, forex }

class Transaction {
  final String id;
  final TransactionType type;
  final String symbol;
  final String name;
  final double amount;
  final double shares;
  final DateTime date;
  final String currency;

  Transaction({
    required this.id,
    required this.type,
    required this.symbol,
    required this.name,
    required this.amount,
    required this.shares,
    required this.date,
    required this.currency,
  });
}

class Holding {
  final String symbol;
  final String name;
  final double value;
  final double change;
  final double changePercentage;
  final IconData icon;
  final HoldingType type;

  Holding({
    required this.symbol,
    required this.name,
    required this.value,
    required this.change,
    required this.changePercentage,
    required this.icon,
    required this.type,
  });
}

class PortfolioStats {
  final double totalValue;
  final double availableBalance;
  final double totalProfit;
  final double totalReturn;
  final double dayChange;

  PortfolioStats({
    required this.totalValue,
    required this.availableBalance,
    required this.totalProfit,
    required this.totalReturn,
    required this.dayChange,
  });
}