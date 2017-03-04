port module Ports exposing (emptyOptions, highlightCode)


type alias EmptyRecord =
    {}


port highlightCode : EmptyRecord -> Cmd msg


emptyOptions : EmptyRecord
emptyOptions =
    EmptyRecord
