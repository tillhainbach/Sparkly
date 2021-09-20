//
//  helpers.swift
//  SparklyExample
//
//  Created by Till Hainbach on 19.09.21.
//

import Foundation

extension Date {
  func toString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .full
    return dateFormatter.string(from: self)
  }
}

func noop() {}

func noop<A>(_ _: A) {}
func noop<A, B>(_ _: A, _ _: B) {}
func noop<A, B, C>(_ _: A, _ _: B, _ _: C) {}
