// External consumer: compiled by the installed runtime, outside upstream Src.
I64 SmokeFactorial(I64 n)
{
    if (n <= 1)
        return 1;
    return n * SmokeFactorial(n - 1);
}

I64 SmokeBranch(I64 n)
{
    if (n < 0)
        return -7;
    if (n == 0)
        return 3;
    return n * 2;
}

I64 arithmetic = 6 * 7;
I64 total = 0;
I64 i;
for (i = 1; i <= 10; i++)
    total += i;
I64 recursion = SmokeFactorial(6);
if (arithmetic != 42 || total != 55 || recursion != 720 ||
    SmokeBranch(-1) != -7 || SmokeBranch(0) != 3 || SmokeBranch(21) != 42) {
    "AIWNIOS_HELLO_FAIL\n";
    ExitAiwnios(23);
}
"AIWNIOS_ARITHMETIC=%d\n", arithmetic;
"AIWNIOS_LOOP=%d\n", total;
"AIWNIOS_BRANCH=%d,%d,%d\n", SmokeBranch(-1), SmokeBranch(0), SmokeBranch(21);
"AIWNIOS_RECURSION=%d\n", recursion;
"AIWNIOS_HELLO_OK\n";
ExitAiwnios(0);
