//
//  StatusItemView.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-30.
//

import SwiftUI

struct StatusItemView: View {
    
    @StateObject var viewModel: ViewModel

    var body: some View {
        HStack(spacing: 1) {
            
            HStack(alignment: .top, spacing: 1) {
                ForEach(viewModel.contributions, id:\.self) { week in
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(week.contributionDays, id:\.date) { day in
                            Rectangle()
                                .fill(Color(hex: day.color))
                                .frame(width: 2, height: 2)
                        }
                    }
                }
            }
            
            
            
            //            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            //                ForEach(viewModel.contributions, id:\.self) { week in
            //                    GridRow {
            //                        ForEach(week.contributionDays, id:\.self) { day in
            //                            Rectangle()
            //                                .fill(Color(hex: day.color))
            //                                .frame(width: 2, height: 2)
            //                        }
            //                    }
            //                }
            //            }
            
        }
    }
}

struct StatusItemView_Previews: PreviewProvider {
    static var previews: some View {
        StatusItemView(viewModel: ViewModel())
    }
}
