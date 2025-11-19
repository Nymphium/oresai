open Locator

type _ action += Ping : (unit, [> Errors.t ]) Result.t action
