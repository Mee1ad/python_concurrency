1 - example of a two-way superScalar execution of instruction

2 - ilp
instruction level parallel

3 - ساختار سلسله مراتب حافظه را در سیستم های کامپیوتری بنویسید؟
هارد دیسک ها

4 - کش چگونه راندمان رو بهتر میکنه؟

5 - مشخصات حافظه اصلی خود را بنویسید

6 - برنامه جمع دو ماتریس را بصورت سطری و ستونی بنویسید و نمودار کارایی ان بنویسید

a = [b[i][j] + c[i][j] for i, j in zip(range(m), range(n))] # column
a = [b[j][i] + c[j][i] for i, j in zip(range(m), range(n))] # row

8 processor to 8 memory with 2 i/o

 p1  a1   b1   c1   m1
 p2  a2   b2   c2   m2
 p3  a3   b3   c3   m3
 p4  a4   b4   c4   m4

p1-a1 a1-b1 b1-c1 c1-m1
p1-a2 a1-b2 b1-c2 c1-m2

p2-a3 a2-b3..



با یک مثال نحوه استفاده پردازش موازی را در بانک اطلاعات نشان دهید


parallel linq

a = b * c if x > y else a = b + c
