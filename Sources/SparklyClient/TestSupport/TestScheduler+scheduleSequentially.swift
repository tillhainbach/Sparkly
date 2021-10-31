//
//  File.swift
//
//
//  Created by Till Hainbach on 31.10.21.
//
#if DEBUG

import CombineSchedulers

extension TestScheduler {
  public func scheduleSequentially(_ actions: () -> Void...) {
    actions.enumerated()
      .forEach { index, action in
        self.schedule(after: self.now.advanced(by: .seconds(index)), action)
      }
  }
}

#endif
