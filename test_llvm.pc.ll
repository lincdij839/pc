; ModuleID = 'main'
target triple = "x86_64-pc-linux-gnu"

; External declarations
declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)

; String constants
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.str.0 = private unnamed_addr constant [17 x i8] c"Hello from LLVM!\00"

; Main function
define i32 @main() {
  entry:
  call i32 @puts(i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.0, i32 0, i32 0))
  call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 42)
  ret i32 0
}
