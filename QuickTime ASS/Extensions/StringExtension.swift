//
//  StringExtension.swift
//  QuickTime ASS
//
//  Created by xjbeta on 2/19/21.
//

import Cocoa

extension String {
    enum TruncationPosition {
        case head
        case middle
        case tail
    }

   func truncated(limit: Int, position: TruncationPosition = .tail, leader: String = "...") -> String {
        guard self.count >= limit else { return self }

        switch position {
        case .head:
            return leader + self.suffix(limit)
        
        case .middle:
            let halfCount = (limit - leader.count).quotientAndRemainder(dividingBy: 2)
            let headCharactersCount = halfCount.quotient + halfCount.remainder
            let tailCharactersCount = halfCount.quotient
            return String(self.prefix(headCharactersCount)) + leader + String(self.suffix(tailCharactersCount))
        
        case .tail:
            return self.prefix(limit) + leader
        }
    }
}
