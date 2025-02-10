// Реализация логического вентиля NOT с помощью структурных примитивов
module not_gate(in, out);
  // Входные порты помечаются как input, выходные как output
  input wire in;
  output wire out;
  // Ключевое слово wire для обозначения типа данных можно опустить,
  // тогда оно подставится неявно, например:
  /*
    input in;
    output out;
  */

  supply1 vdd; // Напряжение питания
  supply0 gnd; // Напряжение земли

  // p-канальный транзистор, сток = out, исток = vdd, затвор = in
  pmos pmos1(out, vdd, in); // (сток, исток, база)
  // n-канальный транзистор, сток = out, исток = gnd, затвор = in
  nmos nmos1(out, gnd, in);
endmodule

// Реализация NAND с помощью структурных примитивов
module nand_gate(in1, in2, out);
  input wire in1;
  input wire in2;
  output wire out;

  supply0 gnd;
  supply1 pwr;

  // С помощью типа wire можно определять промежуточные провода для соединения элементов.
  // В данном случае nmos1_out соединяет сток транзистора nmos1 и исток транзистора nmos2.
  wire nmos1_out;

  // 2 p-канальных и 2 n-канальных транзистора
  pmos pmos1(out, pwr, in1);
  pmos pmos2(out, pwr, in2);
  nmos nmos1(nmos1_out, gnd, in1);
  nmos nmos2(out, nmos1_out, in2);
endmodule

// Реализация NOR с помощью структурных примитивов
module nor_gate(in1, in2, out);
  input wire in1;
  input wire in2;
  output wire out;

  supply0 gnd;
  supply1 pwr;

  // Промежуточный провод, чтобы содединить сток pmos1 и исток pmos2
  wire pmos1_out;

  pmos pmos1(pmos1_out, pwr, in1);
  pmos pmos2(out, pmos1_out, in2);
  nmos nmos1(out, gnd, in1);
  nmos nmos2(out, gnd, in2);
endmodule

// Реализация AND с помощью NAND и NOT
module and_gate(in1, in2, out);
  input wire in1;
  input wire in2;
  output wire out;

  // Промежуточный провод, чтобы передать выход вентиля NAND на вход вентилю NOT
  wire nand_out;

  // Схема для формулы AND(in1, in2) = NOT(NAND(in1, in2))
  nand_gate nand_gate1(in1, in2, nand_out);
  not_gate not_gate1(nand_out, out);
endmodule

// Реализация OR с помощью NOR и NOT
module or_gate(in1, in2, out);
  input wire in1;
  input wire in2;
  output wire out;

  wire nor_out;

  // Схема для формулы OR(in1, in2) = NOT(NOR(in1, in2))
  nor_gate nor_gate1(in1, in2, nor_out);
  not_gate not_gate1(nor_out, out);
endmodule



module decode_ternary(
    input  wire [1:0] in,
    output wire is_minus,
    output wire is_zero,
    output wire is_plus
);
  // "-" = 00
  // "0" = 01
  // "+" = 10

  wire not_in1, not_in0;
  not_gate inv1(in[1], not_in1);
  not_gate inv0(in[0], not_in0);

  // is_minus = ~in[1] & ~in[0]
  and_gate a_minus(not_in1, not_in0, is_minus);

  // is_zero = ~in[1] &  in[0]
  and_gate a_zero(not_in1, in[0], is_zero);

  // is_plus =  in[1] & ~in[0]
  and_gate a_plus(in[1], not_in0, is_plus);
endmodule

module encode_ternary(
    input wire is_minus,
    input wire is_zero,
    input wire is_plus,
    output wire [1:0] out
);

  assign out[1] = is_plus;
  assign out[0] = is_zero;
endmodule

module ternary_min(
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [1:0] out
);
  wire a_minus, a_zero, a_plus;
  decode_ternary decA(a, a_minus, a_zero, a_plus);

  wire b_minus, b_zero, b_plus;
  decode_ternary decB(b, b_minus, b_zero, b_plus);

  wire out_minus;
  or_gate or_m(a_minus, b_minus, out_minus);

  wire not_out_minus;
  not_gate inv1(out_minus, not_out_minus);

  wire zero_or;
  or_gate or_z(a_zero, b_zero, zero_or);

  wire out_zero;
  and_gate and_z(not_out_minus, zero_or, out_zero);

  wire minus_or_zero;
  or_gate or_mz(out_minus, out_zero, minus_or_zero);

  wire out_plus;
  not_gate inv2(minus_or_zero, out_plus);

  encode_ternary enc(out_minus, out_zero, out_plus, out);
endmodule


module ternary_max(
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [1:0] out
);
  wire a_minus, a_zero, a_plus;
  decode_ternary decA(a, a_minus, a_zero, a_plus);

  wire b_minus, b_zero, b_plus;
  decode_ternary decB(b, b_minus, b_zero, b_plus);

  wire out_plus;
  or_gate or_p(a_plus, b_plus, out_plus);

  wire not_out_plus;
  not_gate inv1(out_plus, not_out_plus);

  wire zero_or;
  or_gate or_z(a_zero, b_zero, zero_or);

  wire out_zero;
  and_gate and_z(not_out_plus, zero_or, out_zero);

  wire plus_or_zero;
  or_gate or_pz(out_plus, out_zero, plus_or_zero);

  wire out_minus;
  not_gate inv2(plus_or_zero, out_minus);

  encode_ternary enc(out_minus, out_zero, out_plus, out);
endmodule

module ternary_consensus(
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [1:0] out
);
  wire a_minus, a_zero, a_plus;
  decode_ternary decA(a, a_minus, a_zero, a_plus);

  wire b_minus, b_zero, b_plus;
  decode_ternary decB(b, b_minus, b_zero, b_plus);

  wire out_minus;
  and_gate and_m(a_minus, b_minus, out_minus);

  wire out_plus;
  and_gate and_p(a_plus, b_plus, out_plus);

  wire minus_or_plus;
  or_gate or_mp(out_minus, out_plus, minus_or_plus);

  wire out_zero;
  not_gate inv_z(minus_or_plus, out_zero);

  encode_ternary enc(out_minus, out_zero, out_plus, out);
endmodule

module ternary_any(
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [1:0] out
);
  wire a_minus, a_zero, a_plus;
  decode_ternary decA(a, a_minus, a_zero, a_plus);

  wire b_minus, b_zero, b_plus;
  decode_ternary decB(b, b_minus, b_zero, b_plus);

  wire minus_any;
  or_gate or_m(a_minus, b_minus, minus_any);

  wire plus_any;
  or_gate or_p(a_plus, b_plus, plus_any);

  wire not_plus_any;
  not_gate inv_p(plus_any, not_plus_any);

  wire out_minus;
  and_gate and_m(minus_any, not_plus_any, out_minus);

  wire not_minus_any;
  not_gate inv_m(minus_any, not_minus_any);

  wire out_plus;
  and_gate and_p(plus_any, not_minus_any, out_plus);

  wire minus_or_plus;
  or_gate or_mp(out_minus, out_plus, minus_or_plus);

  wire out_zero;
  not_gate inv_z(minus_or_plus, out_zero);

  encode_ternary enc(
    .is_minus(out_minus), 
    .is_zero(out_zero), 
    .is_plus(out_plus), 
    .out(out)
  );
endmodule