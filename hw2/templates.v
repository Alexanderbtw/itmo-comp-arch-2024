module alu(a, b, control, res);
  input [3:0] a, b; // Операнды
  input [2:0] control; // Управляющие сигналы для выбора операции

  output [3:0] res; // Результат
  wire [3:0] and_ab, and_anb, or_ab, or_anb, sub_ab, add_ab, slt_res;
  wire slt_bit;
  wire sign_a, sign_b, diff_sign;
  
  assign and_ab  = a & b;
  assign and_anb = a & ~b;
  assign or_ab   = a | b;
  assign or_anb  = a | ~b;
  assign sub_ab  = a - b;
  assign add_ab  = a + b;
  
  assign sign_a    = a[3];
  assign sign_b    = b[3];
  assign diff_sign = sign_a ^ sign_b;
  assign slt_bit   = (diff_sign & sign_a) | (~diff_sign & sub_ab[3]);
  assign slt_res   = {3'b000, slt_bit};
  
  // Мультиплексор типа
  assign res = (control == 3'b000) ? and_ab   :
               (control == 3'b001) ? and_anb  :
               (control == 3'b010) ? or_ab    :
               (control == 3'b011) ? or_anb   :
               (control == 3'b100) ? sub_ab   :
               (control == 3'b101) ? add_ab   :
               (control == 3'b110) ? slt_res  :
                                     4'b0000;
endmodule

module d_latch(clk, d, we, q);
  input clk; // Сигнал синхронизации
  input d; // Бит для записи в ячейку
  input we; // Необходимо ли перезаписать содержимое ячейки

  output reg q; // Сама ячейка
  // Изначально в ячейке хранится 0
  initial begin
    q <= 0;
  end
  // Значение изменяется на переданное на спаде сигнала синхронизации
  always @ (negedge clk) begin
    // Запись происходит при we = 1
    if (we) begin
      q <= d;
    end
  end
endmodule

module register_file(clk, rd_addr, we_addr, we_data, rd_data, we);
  input clk; // Сигнал синхронизации
  input [1:0] rd_addr, we_addr; // Номера регистров для чтения и записи
  input [3:0] we_data; // Данные для записи в регистровый файл
  input we; // Необходимо ли перезаписать содержимое регистра

  output [3:0] rd_data; // Данные, полученные в результате чтения из регистрового файла
  // Дешифратор
  wire [3:0] we_vec;
  dec2to4 we_dec (.a(we_addr), .en(we), .y(we_vec));

  // регистры
  wire [3:0] reg0, reg1, reg2, reg3;
  
  // TODO: do smt with copy-paste
  d_latch dl0_0(.clk(clk), .d(we_data[0]), .we(we_vec[0]), .q(reg0[0]));
  d_latch dl0_1(.clk(clk), .d(we_data[1]), .we(we_vec[0]), .q(reg0[1]));
  d_latch dl0_2(.clk(clk), .d(we_data[2]), .we(we_vec[0]), .q(reg0[2]));
  d_latch dl0_3(.clk(clk), .d(we_data[3]), .we(we_vec[0]), .q(reg0[3]));

  d_latch dl1_0(.clk(clk), .d(we_data[0]), .we(we_vec[1]), .q(reg1[0]));
  d_latch dl1_1(.clk(clk), .d(we_data[1]), .we(we_vec[1]), .q(reg1[1]));
  d_latch dl1_2(.clk(clk), .d(we_data[2]), .we(we_vec[1]), .q(reg1[2]));
  d_latch dl1_3(.clk(clk), .d(we_data[3]), .we(we_vec[1]), .q(reg1[3]));

  d_latch dl2_0(.clk(clk), .d(we_data[0]), .we(we_vec[2]), .q(reg2[0]));
  d_latch dl2_1(.clk(clk), .d(we_data[1]), .we(we_vec[2]), .q(reg2[1]));
  d_latch dl2_2(.clk(clk), .d(we_data[2]), .we(we_vec[2]), .q(reg2[2]));
  d_latch dl2_3(.clk(clk), .d(we_data[3]), .we(we_vec[2]), .q(reg2[3]));

  d_latch dl3_0(.clk(clk), .d(we_data[0]), .we(we_vec[3]), .q(reg3[0]));
  d_latch dl3_1(.clk(clk), .d(we_data[1]), .we(we_vec[3]), .q(reg3[1]));
  d_latch dl3_2(.clk(clk), .d(we_data[2]), .we(we_vec[3]), .q(reg3[2]));
  d_latch dl3_3(.clk(clk), .d(we_data[3]), .we(we_vec[3]), .q(reg3[3]));


  // Мультиплексор для чтения
  mux4 #(.WIDTH(4)) rd_mux (
    .d0 (reg0), .d1 (reg1), .d2 (reg2), .d3 (reg3),
    .sel(rd_addr),
    .y  (rd_data)
  );
endmodule

module counter(clk, addr, control, immediate, data);
  input clk; // Сигнал синхронизации
  input [1:0] addr; // Номер значения счетчика которое читается или изменяется
  input [3:0] immediate; // Целочисленная константа, на которую увеличивается/уменьшается значение счетчика
  input control; // 0 - операция инкремента, 1 - операция декремента

  output [3:0] data; // Данные из значения под номером addr, подающиеся на выход

  wire [3:0] we_value;
  assign we_value = control ? (data - immediate) : (data + immediate);

  register_file rf_counter (
    .clk     (clk),
    .rd_addr (addr),
    .we_addr (addr),
    .we_data (we_value),
    .we      (1'b1),
    .rd_data (data)
  );
endmodule





// Дешифратор 2‑к‑4
module dec2to4(input [1:0] a, input en, output wire [3:0] y);
  assign y = en ? (4'b0001 << a) : 4'b0000;
endmodule

// Универсальный 4‑к‑1 мультиплексор на N бит
module mux4 #(parameter WIDTH = 1)
             (input  [WIDTH-1:0] d0, d1, d2, d3,
              input  [1:0]       sel,
              output [WIDTH-1:0] y);

  assign y = (sel == 2'b00) ? d0 :
             (sel == 2'b01) ? d1 :
             (sel == 2'b10) ? d2 :
                              d3;
endmodule