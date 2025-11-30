enum InvestmentType { single, recurring }

enum Frequency { monthly, weekly }

class InvestmentConfig {
  String asset; // 'bitcoin' or 'tesla'
  int yearsAgo;
  double amount;
  InvestmentType type;
  Frequency frequency;

  InvestmentConfig({
    this.asset = 'bitcoin',
    this.yearsAgo = 5,
    this.amount = 1000,
    this.type = InvestmentType.single,
    this.frequency = Frequency.monthly,
  });
}
