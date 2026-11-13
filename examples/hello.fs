// F# is a guest language in the F++ project.
// TOASTER still handles the final Lua translation.
let main () =
    let chaos = 100
    if chaos > 50 then
        printfn "F# says RANDOM BS GO!"
    else
        printfn "F# says C'est joever."
    0

main ()
