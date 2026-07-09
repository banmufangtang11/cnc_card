module 	en_assign(
  xen,yen,zen,aen,
  px_out,py_out,pz_out,pa_out,
  px_in,py_in,pz_in,pa_in);
  
input xen,yen,zen,aen;
input px_in,py_in,pz_in,pa_in;
output px_out,py_out,pz_out,pa_out;

assign	px_out =  (xen) ? 1'h0 : px_in;
assign	py_out =  (yen) ? 1'h0 : py_in;
assign	pz_out =  (zen) ? 1'h0 : pz_in;
assign	pa_out =  (aen) ? 1'h0 : pa_in;

endmodule 