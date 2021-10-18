//
//  LineChartData.swift
//  Line Chart
//
//  Created by Mivic Ollennu.
//
import Foundation

struct LineChartData : Identifiable {
    var id: String
    var xLabel: Double
    var yLabel: Double
}

func makeLineChartCumulative(original: [LineChartData]) -> [LineChartData] {
    var result: [LineChartData] = []
    if(original.count > 0) {
    result.append(original[0])
    if(original.count > 1) {
    for index in 1...original.count - 1 {
        result.append(LineChartData(id: original[index].id, xLabel: original[index].xLabel, yLabel: original[index].yLabel + result[index - 1].yLabel))
    }
    }
    }
    return result
}
