
import SwiftUI
import Charts

private struct SeatPairProfit: Identifiable {
    let id: String
    let label: String
    let profit: Double
}

private struct SectionROI: Identifiable {
    let id: String
    let section: String
    let roi: Double
}

struct AnalyticsView: View {
    // Average price per set per section
    private var averagePricePerSetPerSection: [(section: String, average: Double)] {
        guard let pass else { return [] }
        let sectionGroups = Dictionary(grouping: pass.seatPairs, by: { $0.section })
        return sectionGroups.keys.sorted().map { section in
            let pairs = sectionGroups[section] ?? []
            // Gather all sales for all seat pairs in this section
            let allSales = pairs.flatMap { pair in
                pass.sales.filter { sale in
                    sale.section == pair.section && sale.row == pair.row && sale.seats == pair.seats
                }
            }
            let total = allSales.reduce(0.0) { sum, sale in sum + sale.price }
            let count = Double(allSales.count)
            let avg = count > 0 ? total / count : 0.0
            return (section, avg)
        }
    }

        // MARK: - Auto Profit Intelligence Computed Properties
        private var profitPerGame: [GameProfit] {
            guard let pass else { return [] }
            let costPerGame = pass.seatPairs.reduce(0) { sum, pair in sum + pair.cost } / Double(max(pass.games.count, 1))
            return pass.games.map { game in
                let sales = pass.sales.filter { sale in sale.gameId == game.id }
                let revenue = sales.reduce(0) { sum, sale in sum + sale.price }
                let profit = revenue - costPerGame
                return GameProfit(id: game.id, label: game.gameLabel.isEmpty ? game.opponent : game.gameLabel, profit: profit)
            }
        }

        private var profitPerSeatPair: [SeatPairProfit] {
            guard let pass else { return [] }
            return pass.seatPairs.map { pair in
                let sales = pass.sales.filter { sale in
                    sale.section == pair.section && sale.row == pair.row && sale.seats == pair.seats
                }
                let revenue = sales.reduce(0) { sum, sale in sum + sale.price }
                let profit = revenue - pair.cost
                return SeatPairProfit(id: pair.id, label: "Sec \(pair.section) Row \(pair.row) Seats \(pair.seats)", profit: profit)
            }
        }

        private var roiBySection: [SectionROI] {
            guard let pass else { return [] }
            let sectionGroups = Dictionary(grouping: pass.seatPairs, by: { pair in pair.section })
            return sectionGroups.keys.sorted().map { section in
                let pairs = sectionGroups[section] ?? []
                let totalCost = pairs.reduce(0) { sum, pair in sum + pair.cost }
                let totalRevenue = pairs.reduce(0) { sum, pair in
                    let sales = pass.sales.filter { sale in
                        sale.section == pair.section && sale.row == pair.row && sale.seats == pair.seats
                    }
                    return sum + sales.reduce(0) { saleSum, sale in saleSum + sale.price }
                }
                let roi = totalCost > 0 ? (totalRevenue - totalCost) / totalCost : 0
                return SectionROI(id: section, section: section, roi: roi)
            }
        }

        private var bestGame: GameProfit? {
            profitPerGame.max(by: { $0.profit < $1.profit })
        }

        private var worstGame: GameProfit? {
            profitPerGame.min(by: { $0.profit < $1.profit })
        }

        // Analytics header
        private var analyticsHeader: some View {
            Text("Analytics")
                .font(.largeTitle)
                .padding(.top, 16)
        }

    // Helper struct for profitPerGame
    private struct GameProfit: Identifiable {
        let id: String
        let label: String
        let profit: Double
    }
    @Environment(DataStore.self) private var store

    private var pass: SeasonPass? { store.activePass }

    private var allSeasonMonths: [(String, Double, Date)] {
        guard let pass else { return [] }
        let calendar = Calendar.current

        let allDates = pass.games.map(\.date) + pass.sales.map(\.soldDate)
        guard let earliest = allDates.min(), let latest = allDates.max() else { return [] }

        let salesGrouped = Dictionary(grouping: pass.sales) { sale in
            calendar.dateComponents([.year, .month], from: sale.soldDate)
        }

        var result: [(String, Double, Date)] = []
        var current = calendar.date(from: calendar.dateComponents([.year, .month], from: earliest)) ?? earliest
        let end = calendar.date(from: calendar.dateComponents([.year, .month], from: latest)) ?? latest

        while current <= end {
            let comps = calendar.dateComponents([.year, .month], from: current)
            let label = current.formatted(.dateTime.month(.abbreviated))
            let total = salesGrouped[comps]?.reduce(0) { $0 + $1.price } ?? 0
            result.append((label, total, current))
            guard let next = calendar.date(byAdding: .month, value: 1, to: current) else { break }
            current = next
        }
        return result
    }

    // MARK: - Auto Profit Intelligence Section
    private var autoProfitIntelligenceSection: some View {
        Group {
            if pass != nil {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Auto Profit Intelligence")
                        .font(.title3.bold())
                        .padding(.bottom, 2)

                    // Average Price Per Set Per Section
                    Text("Average Price Per Set Per Section")
                        .font(.headline)
                    ForEach(averagePricePerSetPerSection, id: \.section) { item in
                        HStack {
                            Text("Section \(item.section)")
                            Spacer()
                            Text(item.average, format: .currency(code: "USD"))
                        }
                        .font(.subheadline)
                    }

                    Divider()

                    // Profit per Game
                    Text("Profit per Game")
                        .font(.headline)
                    ForEach(profitPerGame) { item in
                        HStack {
                            Text(item.label)
                            Spacer()
                            Text(item.profit, format: .currency(code: "USD"))
                                .foregroundStyle(item.profit >= 0 ? .green : .red)
                        }
                        .font(.subheadline)
                    }

                    Divider()

                    // Profit per Seat Pair
                    Text("Profit per Seat Pair")
                        .font(.headline)
                    ForEach(profitPerSeatPair) { item in
                        HStack {
                            Text(item.label)
                            Spacer()
                            Text(item.profit, format: .currency(code: "USD"))
                                .foregroundStyle(item.profit >= 0 ? .green : .red)
                        }
                        .font(.subheadline)
                    }

                    Divider()

                    // ROI by Section
                    Text("ROI by Section")
                        .font(.headline)
                    ForEach(roiBySection) { item in
                        HStack {
                            Text("Section \(item.section)")
                            Spacer()
                            Text("ROI: \(item.roi, format: .percent.precision(.fractionLength(1)))")
                        }
                        .font(.subheadline)
                    }

                    Divider()

                    // Best/Worst Games to Sell
                    Text("Best / Worst Games to Sell")
                        .font(.headline)
                    if let best = bestGame {
                        HStack {
                            Text("Best: \(best.label)")
                            Spacer()
                            Text(best.profit, format: .currency(code: "USD"))
                                .foregroundStyle(.green)
                        }
                        .font(.subheadline)
                    }
                    if let worst = worstGame {
                        HStack {
                            Text("Worst: \(worst.label)")
                            Spacer()
                            Text(worst.profit, format: .currency(code: "USD"))
                                .foregroundStyle(.red)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
    }

    private var hasSalesData: Bool {
        allSeasonMonths.contains { $0.1 > 0 }
    }

    private var seatPairPerformance: [(SeatPair, Double, Int, Double)] {
        guard let pass else { return [] }
        return pass.seatPairs.map { pair in
            let sales = store.salesForSeatPair(section: pair.section, row: pair.row, seats: pair.seats)
            let revenue = sales.reduce(0) { $0 + $1.price }
            let gamesSold = Set(sales.map(\.gameId)).count
            let balance = revenue - pair.cost
            return (pair, revenue, gamesSold, balance)
        }
    }

    private var soldRate: Double {
        guard let pass, !pass.games.isEmpty, !pass.seatPairs.isEmpty else { return 0 }
        let totalPossible = pass.games.count * pass.seatPairs.count
        guard totalPossible > 0 else { return 0 }
        return Double(pass.totalSeatsSold) / Double(totalPossible) * 100
    }

    private var theme: TeamTheme { store.currentTheme }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    analyticsHeader

                    VStack(spacing: 20) {
                        overviewCards
                        revenueChart
                        seatPerformanceSection
                        seasonTotals
                        autoProfitIntelligenceSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    BottomLogoView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Analytics")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var overviewCards: some View {
        HStack(spacing: 12) {
            AnalyticCard(
                title: "Revenue",
                value: (pass?.totalRevenue ?? 0).formatted(.currency(code: "USD").precision(.fractionLength(0))),
                icon: "dollarsign.circle.fill",
                color: .green
            )
            AnalyticCard(
                title: "Seats Sold",
                value: "\(pass?.totalSeatsSold ?? 0)",
                icon: "ticket.fill",
                color: store.currentTheme.primary
            )
            AnalyticCard(
                title: "Sold Rate",
                value: "\(Int(soldRate))%",
                icon: "chart.pie.fill",
                color: .blue
            )
        }
    }

    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Monthly Revenue")
                .font(.subheadline.weight(.semibold))

            if allSeasonMonths.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("No schedule data yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
            } else {
                let totalRev = allSeasonMonths.reduce(0) { $0 + $1.1 }
                Text(totalRev, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    Chart {
                        ForEach(allSeasonMonths, id: \.2) { month, revenue, date in
                            BarMark(
                                x: .value("Month", month),
                                y: .value("Revenue", revenue),
                                width: .fixed(16)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [store.currentTheme.primary, store.currentTheme.secondary],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .clipShape(.rect(cornerRadius: 3, style: .continuous))
                            .annotation(position: .top, spacing: 2) {
                                if revenue > 0 {
                                    Text(revenue, format: .currency(code: "USD").precision(.fractionLength(0)))
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let val = value.as(Double.self) {
                                    Text("$\(Int(val))")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.caption2)
                        }
                    }
                    .frame(width: max(CGFloat(allSeasonMonths.count) * 56, 180), height: 120)
                }
                .defaultScrollAnchor(.trailing)
                .contentMargins(.horizontal, 2)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private var seatPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seat Pair Performance")
                .font(.headline)

            if seatPairPerformance.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chair.lounge")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Add seat pairs to track performance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(seatPairPerformance, id: \.0.id) { pair, revenue, gamesSold, balance in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sec \(pair.section) Row \(pair.row)")
                                .font(.subheadline.weight(.medium))
                            Text("Seats: \(pair.seats)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(revenue, format: .currency(code: "USD"))
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            HStack(spacing: 8) {
                                Text("\(gamesSold) games")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(balance, format: .currency(code: "USD"))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(balance >= 0 ? .green : .red)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private var seasonTotals: some View {
        VStack(spacing: 12) {
            Text("Season Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("Season Cost")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(pass?.totalSeasonCost ?? 0, format: .currency(code: "USD"))
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            HStack {
                Text("Sales to Date")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(pass?.totalRevenue ?? 0, format: .currency(code: "USD"))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Divider()

            HStack {
                Text("Net P/L")
                    .font(.headline)
                Spacer()
                let pnl = pass?.netProfitLoss ?? 0
                Text(pnl, format: .currency(code: "USD"))
                    .font(.title3.bold())
                    .foregroundStyle(pnl >= 0 ? .green : .red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

}

struct AnalyticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 8))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
}
