	.file	""
	.data
	.globl	_camlTest_pretty_print$data_begin
_camlTest_pretty_print$data_begin:
	.text
	.globl	_camlTest_pretty_print$code_begin
_camlTest_pretty_print$code_begin:
	nop
	.align	3
	.data
	.align	3
	.data
	.align	3
	.quad	3063
	.globl	_camlTest_pretty_print$36
_camlTest_pretty_print$36:
	.quad	_camlTest_pretty_print$main_291
	.quad	72057594037927941
	.data
	.align	3
	.quad	16128
	.globl	_camlTest_pretty_print
	.globl	_camlTest_pretty_print
_camlTest_pretty_print:
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.quad	1
	.data
	.align	3
	.globl	_camlTest_pretty_print$gc_roots
	.globl	_camlTest_pretty_print$gc_roots
_camlTest_pretty_print$gc_roots:
	.quad	_camlTest_pretty_print
	.quad	0
	.text
	.align	3
	.globl	_camlTest_pretty_print$main_291
L102:
	mov	x16, #34
	stp	x16, x30, [sp, #-16]!
	bl	_caml_call_realloc_stack
	ldp	x16, x30, [sp], #16
_camlTest_pretty_print$main_291:
	.cfi_startproc
	ldr	x16, [x28, #40]
	add	x16, x16, #328
	cmp	sp, x16
	bcc	L102
L103:
L104:
	str	x30, [sp, #-8]
	.cfi_offset 30, -8
	sub	sp, sp, #16
	.cfi_adjust_cfa_offset	16
	.ifne (. - L104) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L105:
L101:
	.ifne (. - L105) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L106:
	adrp	x1, _camlTest_pretty_print$26@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$26@GOTPAGEOFF]
	.ifne (. - L106) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L107:
	adrp	x2, _camlStdlib@GOTPAGE
	ldr	x2, [x2, _camlStdlib@GOTPAGEOFF]
	.ifne (. - L107) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L108:
L109:
	ldr	x0, [x2, #304]
	.ifne (. - L108) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L110:
	bl	_camlStdlib__Printf$fprintf_431
L111:
	.ifne (. - L110) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L112:
	adrp	x1, _camlTest_pretty_print$29@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$29@GOTPAGEOFF]
	.ifne (. - L112) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L113:
	adrp	x5, _camlStdlib@GOTPAGE
	ldr	x5, [x5, _camlStdlib@GOTPAGEOFF]
	.ifne (. - L113) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L114:
	ldr	x0, [x5, #304]
	.ifne (. - L114) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L115:
	bl	_camlStdlib__Printf$fprintf_431
L116:
	.ifne (. - L115) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L117:
	adrp	x1, _camlTest_pretty_print$32@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$32@GOTPAGEOFF]
	.ifne (. - L117) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L118:
	adrp	x8, _camlStdlib@GOTPAGE
	ldr	x8, [x8, _camlStdlib@GOTPAGEOFF]
	.ifne (. - L118) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L119:
	ldr	x0, [x8, #304]
	.ifne (. - L119) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L120:
	bl	_camlStdlib__Printf$fprintf_431
L121:
	.ifne (. - L120) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L122:
	adrp	x1, _camlTest_pretty_print$35@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$35@GOTPAGEOFF]
	.ifne (. - L122) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L123:
	adrp	x11, _camlStdlib@GOTPAGE
	ldr	x11, [x11, _camlStdlib@GOTPAGEOFF]
	.ifne (. - L123) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L124:
	ldr	x0, [x11, #304]
	.ifne (. - L124) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L125:
	bl	_camlStdlib__Printf$fprintf_431
L126:
	.ifne (. - L125) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L127:
	orr	x0, xzr, #1
	.ifne (. - L127) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L128:
	.ifne (. - L128) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L129:
	add	sp, sp, #16
	.cfi_adjust_cfa_offset	-16
	ldr	x30, [sp, #-8]
	and	x30, x30, #0x00FFFFFFFFFFFFFF
	ret
	.cfi_adjust_cfa_offset	16
	.ifne (. - L129) - 16
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L130:
L100:
	.ifne (. - L130) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
	.ifne (. - L103) - 124
	.error "Emit.instr_size: instruction length mismatch"
	.endif
	.cfi_endproc
_camlTest_pretty_print$main_291_end:
	.globl	"_Test_pretty_print::main"
	.set	"_Test_pretty_print::main", _camlTest_pretty_print$main_291
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$9
	.globl	_camlTest_pretty_print$9
_camlTest_pretty_print$9:
	.quad	5
	.quad	1
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$8
	.globl	_camlTest_pretty_print$8
_camlTest_pretty_print$8:
	.quad	3
	.quad	_camlTest_pretty_print$7
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$7
	.globl	_camlTest_pretty_print$7
_camlTest_pretty_print$7:
	.quad	5
	.quad	_camlTest_pretty_print$6
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$6
	.globl	_camlTest_pretty_print$6
_camlTest_pretty_print$6:
	.quad	7
	.quad	_camlTest_pretty_print$5
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$5
	.globl	_camlTest_pretty_print$5
_camlTest_pretty_print$5:
	.quad	9
	.quad	_camlTest_pretty_print$4
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$4
	.globl	_camlTest_pretty_print$4
_camlTest_pretty_print$4:
	.quad	11
	.quad	1
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$35
_camlTest_pretty_print$35:
	.quad	_camlTest_pretty_print$34
	.quad	_camlTest_pretty_print$33
	.data
	.align	3
	.quad	2827
	.globl	_camlTest_pretty_print$34
_camlTest_pretty_print$34:
	.quad	_camlTest_pretty_print$33
	.quad	1
	.data
	.align	3
	.quad	5116
	.globl	_camlTest_pretty_print$33
_camlTest_pretty_print$33:
	.ascii  "Lists and options created\12"
	.space	5
	.byte	5
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$32
_camlTest_pretty_print$32:
	.quad	_camlTest_pretty_print$31
	.quad	_camlTest_pretty_print$30
	.data
	.align	3
	.quad	2827
	.globl	_camlTest_pretty_print$31
_camlTest_pretty_print$31:
	.quad	_camlTest_pretty_print$30
	.quad	1
	.data
	.align	3
	.quad	5116
	.globl	_camlTest_pretty_print$30
_camlTest_pretty_print$30:
	.ascii  "complex_tree: constructed\12"
	.space	5
	.byte	5
	.data
	.align	3
	.quad	3840
	.globl	_camlTest_pretty_print$3
	.globl	_camlTest_pretty_print$3
_camlTest_pretty_print$3:
	.quad	21
	.quad	_camlTest_pretty_print$1
	.quad	_camlTest_pretty_print$2
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$29
_camlTest_pretty_print$29:
	.quad	_camlTest_pretty_print$28
	.quad	_camlTest_pretty_print$27
	.data
	.align	3
	.quad	2827
	.globl	_camlTest_pretty_print$28
_camlTest_pretty_print$28:
	.quad	_camlTest_pretty_print$27
	.quad	1
	.data
	.align	3
	.quad	5116
	.globl	_camlTest_pretty_print$27
_camlTest_pretty_print$27:
	.ascii  "simple_tree: constructed\12"
	.space	6
	.byte	6
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$26
_camlTest_pretty_print$26:
	.quad	_camlTest_pretty_print$25
	.quad	_camlTest_pretty_print$24
	.data
	.align	3
	.quad	2827
	.globl	_camlTest_pretty_print$25
_camlTest_pretty_print$25:
	.quad	_camlTest_pretty_print$24
	.quad	1
	.data
	.align	3
	.quad	5116
	.globl	_camlTest_pretty_print$24
_camlTest_pretty_print$24:
	.ascii  "empty_tree: constructed\12"
	.space	7
	.byte	7
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$23
	.globl	_camlTest_pretty_print$23
_camlTest_pretty_print$23:
	.quad	85
	.quad	_camlTest_pretty_print$22
	.data
	.align	3
	.quad	2044
	.globl	_camlTest_pretty_print$22
	.globl	_camlTest_pretty_print$22
_camlTest_pretty_print$22:
	.ascii  "answer"
	.space	1
	.byte	1
	.data
	.align	3
	.quad	3068
	.globl	_camlTest_pretty_print$21
	.globl	_camlTest_pretty_print$21
_camlTest_pretty_print$21:
	.ascii  "hello world"
	.space	4
	.byte	4
	.data
	.align	3
	.quad	2045
	.globl	_camlTest_pretty_print$20
_camlTest_pretty_print$20:
	.quad	0x40091eb851eb851f
	.data
	.align	3
	.quad	3840
	.globl	_camlTest_pretty_print$2
	.globl	_camlTest_pretty_print$2
_camlTest_pretty_print$2:
	.quad	31
	.quad	1
	.quad	1
	.data
	.align	3
	.quad	2045
	.globl	_camlTest_pretty_print$19
_camlTest_pretty_print$19:
	.quad	0x400599999999999a
	.data
	.align	3
	.quad	2045
	.globl	_camlTest_pretty_print$18
_camlTest_pretty_print$18:
	.quad	0x3ff8000000000000
	.data
	.align	3
	.quad	5888
	.globl	_camlTest_pretty_print$17
_camlTest_pretty_print$17:
	.quad	3
	.quad	5
	.quad	7
	.quad	9
	.quad	11
	.data
	.align	3
	.quad	1792
	.globl	_camlTest_pretty_print$16
	.globl	_camlTest_pretty_print$16
_camlTest_pretty_print$16:
	.quad	85
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$15
	.globl	_camlTest_pretty_print$15
_camlTest_pretty_print$15:
	.quad	_camlTest_pretty_print$10
	.quad	_camlTest_pretty_print$14
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$14
	.globl	_camlTest_pretty_print$14
_camlTest_pretty_print$14:
	.quad	_camlTest_pretty_print$12
	.quad	_camlTest_pretty_print$13
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$13
	.globl	_camlTest_pretty_print$13
_camlTest_pretty_print$13:
	.quad	_camlTest_pretty_print$4
	.quad	1
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$12
	.globl	_camlTest_pretty_print$12
_camlTest_pretty_print$12:
	.quad	7
	.quad	_camlTest_pretty_print$11
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$11
	.globl	_camlTest_pretty_print$11
_camlTest_pretty_print$11:
	.quad	9
	.quad	1
	.data
	.align	3
	.quad	2816
	.globl	_camlTest_pretty_print$10
	.globl	_camlTest_pretty_print$10
_camlTest_pretty_print$10:
	.quad	3
	.quad	_camlTest_pretty_print$9
	.data
	.align	3
	.quad	3840
	.globl	_camlTest_pretty_print$1
	.globl	_camlTest_pretty_print$1
_camlTest_pretty_print$1:
	.quad	11
	.quad	1
	.quad	1
	.text
	.align	3
	.globl	_camlTest_pretty_print$entry
L141:
	mov	x16, #34
	stp	x16, x30, [sp, #-16]!
	bl	_caml_call_realloc_stack
	ldp	x16, x30, [sp], #16
_camlTest_pretty_print$entry:
	.cfi_startproc
	ldr	x16, [x28, #40]
	add	x16, x16, #328
	cmp	sp, x16
	bcc	L141
L142:
L143:
	str	x30, [sp, #-8]
	.cfi_offset 30, -8
	sub	sp, sp, #16
	.cfi_adjust_cfa_offset	16
	.ifne (. - L143) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L144:
L140:
	.ifne (. - L144) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L145:
	orr	x1, xzr, #1
	.ifne (. - L145) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L146:
	adrp	x0, _camlTest_pretty_print@GOTPAGE
	ldr	x0, [x0, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L146) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L147:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L147) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L148:
	adrp	x1, _camlTest_pretty_print$1@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$1@GOTPAGEOFF]
	.ifne (. - L148) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L149:
	adrp	x3, _camlTest_pretty_print@GOTPAGE
	ldr	x3, [x3, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L149) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L150:
	add	x0, x3, #8
	.ifne (. - L150) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L151:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L151) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L152:
	adrp	x1, _camlTest_pretty_print$3@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$3@GOTPAGEOFF]
	.ifne (. - L152) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L153:
	adrp	x6, _camlTest_pretty_print@GOTPAGE
	ldr	x6, [x6, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L153) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L154:
	add	x0, x6, #16
	.ifne (. - L154) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L155:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L155) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L156:
	adrp	x1, _camlTest_pretty_print$8@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$8@GOTPAGEOFF]
	.ifne (. - L156) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L157:
	adrp	x9, _camlTest_pretty_print@GOTPAGE
	ldr	x9, [x9, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L157) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L158:
	add	x0, x9, #24
	.ifne (. - L158) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L159:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L159) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L160:
	orr	x1, xzr, #1
	.ifne (. - L160) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L161:
	adrp	x12, _camlTest_pretty_print@GOTPAGE
	ldr	x12, [x12, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L161) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L162:
	add	x0, x12, #32
	.ifne (. - L162) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L163:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L163) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L164:
	adrp	x1, _camlTest_pretty_print$15@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$15@GOTPAGEOFF]
	.ifne (. - L164) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L165:
	adrp	x15, _camlTest_pretty_print@GOTPAGE
	ldr	x15, [x15, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L165) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L166:
	add	x0, x15, #40
	.ifne (. - L166) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L167:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L167) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L168:
	adrp	x1, _camlTest_pretty_print$16@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$16@GOTPAGEOFF]
	.ifne (. - L168) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L169:
	adrp	x21, _camlTest_pretty_print@GOTPAGE
	ldr	x21, [x21, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L169) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L170:
	add	x0, x21, #48
	.ifne (. - L170) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L171:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L171) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L172:
	orr	x1, xzr, #1
	.ifne (. - L172) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L173:
	adrp	x24, _camlTest_pretty_print@GOTPAGE
	ldr	x24, [x24, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L173) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L174:
	add	x0, x24, #56
	.ifne (. - L174) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L175:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L175) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L176:
	orr	x1, xzr, #3
	.ifne (. - L176) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L177:
	adrp	x2, _camlTest_pretty_print@GOTPAGE
	ldr	x2, [x2, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L177) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L178:
	add	x0, x2, #64
	.ifne (. - L178) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L179:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L179) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L180:
	orr	x1, xzr, #1
	.ifne (. - L180) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L181:
	adrp	x4, _camlTest_pretty_print@GOTPAGE
	ldr	x4, [x4, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L181) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L182:
	add	x0, x4, #72
	.ifne (. - L182) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L183:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L183) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L184:
	adrp	x0, _camlTest_pretty_print$17@GOTPAGE
	ldr	x0, [x0, _camlTest_pretty_print$17@GOTPAGEOFF]
	.ifne (. - L184) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L185:
L186:
	adrp	x8, _caml_obj_dup@GOTPAGE
	ldr	x8, [x8, _caml_obj_dup@GOTPAGEOFF]
	bl	_caml_c_call
L187:
	.ifne (. - L185) - 12
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L188:
	mov	x1, x0
	.ifne (. - L188) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L189:
	adrp	x8, _camlTest_pretty_print@GOTPAGE
	ldr	x8, [x8, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L189) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L190:
	add	x0, x8, #80
	.ifne (. - L190) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L191:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L191) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L192:
L193:
	bl	_caml_alloc3
L194:	add	x1, x27, #8
	.ifne (. - L192) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L195:
	movz	x11, #3326, lsl #0
	.ifne (. - L195) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L196:
	str	x11, [x1, #-8]
	.ifne (. - L196) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L197:
	fmov	d0, #1.5000000
	.ifne (. - L197) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L198:
	str	d0, [x1, #0]
	.ifne (. - L198) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L199:
	adrp	x16, L200@PAGE
	ldr	d1, [x16, L200@PAGEOFF]
	.ifne (. - L199) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L201:
	str	d1, [x1, #8]
	.ifne (. - L201) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L202:
	adrp	x16, L203@PAGE
	ldr	d2, [x16, L203@PAGEOFF]
	.ifne (. - L202) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L204:
	str	d2, [x1, #16]
	.ifne (. - L204) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L205:
	adrp	x12, _camlTest_pretty_print@GOTPAGE
	ldr	x12, [x12, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L205) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L206:
	add	x0, x12, #88
	.ifne (. - L206) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L207:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L207) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L208:
	adrp	x1, _camlTest_pretty_print$21@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$21@GOTPAGEOFF]
	.ifne (. - L208) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L209:
	adrp	x15, _camlTest_pretty_print@GOTPAGE
	ldr	x15, [x15, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L209) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L210:
	add	x0, x15, #96
	.ifne (. - L210) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L211:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L211) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L212:
	adrp	x1, _camlTest_pretty_print$23@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$23@GOTPAGEOFF]
	.ifne (. - L212) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L213:
	adrp	x21, _camlTest_pretty_print@GOTPAGE
	ldr	x21, [x21, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L213) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L214:
	add	x0, x21, #104
	.ifne (. - L214) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L215:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L215) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L216:
	adrp	x1, _camlTest_pretty_print$36@GOTPAGE
	ldr	x1, [x1, _camlTest_pretty_print$36@GOTPAGEOFF]
	.ifne (. - L216) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L217:
	adrp	x24, _camlTest_pretty_print@GOTPAGE
	ldr	x24, [x24, _camlTest_pretty_print@GOTPAGEOFF]
	.ifne (. - L217) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L218:
	add	x0, x24, #112
	.ifne (. - L218) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L219:
	mov	x19, sp
	.cfi_remember_state
	.cfi_def_cfa_register 19
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	_caml_initialize
	mov	sp, x19
	.cfi_restore_state
	.ifne (. - L219) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L220:
	orr	x0, xzr, #1
	.ifne (. - L220) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L221:
L222:
	bl	_camlTest_pretty_print$main_291
L223:
	.ifne (. - L221) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L224:
	orr	x0, xzr, #1
	.ifne (. - L224) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L225:
	.ifne (. - L225) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L226:
	add	sp, sp, #16
	.cfi_adjust_cfa_offset	-16
	ldr	x30, [sp, #-8]
	and	x30, x30, #0x00FFFFFFFFFFFFFF
	ret
	.cfi_adjust_cfa_offset	16
	.ifne (. - L226) - 16
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L227:
L137:
	.ifne (. - L227) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L228:
L138:
	.ifne (. - L228) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L229:
L131:
	.ifne (. - L229) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L230:
L132:
	.ifne (. - L230) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L231:
L133:
	.ifne (. - L231) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L232:
L134:
	.ifne (. - L232) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L233:
L135:
	.ifne (. - L233) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
L234:
L136:
	.ifne (. - L234) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
	.ifne (. - L142) - 668
	.error "Emit.instr_size: instruction length mismatch"
	.endif
	.cfi_endproc
_camlTest_pretty_print$entry_end:
	.globl	"_Test_pretty_print::entry"
	.set	"_Test_pretty_print::entry", _camlTest_pretty_print$entry
	.section	__TEXT,__literal8,8byte_literals
	.align	3
L203:	.quad	0x40091eb851eb851f
L200:	.quad	0x400599999999999a
	.data
	.align	3
	.text
	.globl	_camlTest_pretty_print$code_end
_camlTest_pretty_print$code_end:
	.data
	.quad	0
	.globl	_camlTest_pretty_print$data_end
_camlTest_pretty_print$data_end:
	.quad	0
	.align	3
	.globl	_camlTest_pretty_print$frametable
_camlTest_pretty_print$frametable:
	.quad	7
	.quad	L223
	.short	17
	.short	0
	.align	2
	.long	L235 - . + 0x0
	.align	3
	.quad	L194
	.short	19
	.short	0
	.byte	1
	.byte	2
	.align	2
	.long	L236 - . + 0x0
	.align	3
	.quad	L187
	.short	17
	.short	0
	.align	2
	.long	L237 - . + 0x0
	.align	3
	.quad	L126
	.short	17
	.short	0
	.align	2
	.long	L238 - . + 0x0
	.align	3
	.quad	L121
	.short	17
	.short	0
	.align	2
	.long	L239 - . + 0x0
	.align	3
	.quad	L116
	.short	17
	.short	0
	.align	2
	.long	L240 - . + 0x0
	.align	3
	.quad	L111
	.short	17
	.short	0
	.align	2
	.long	L241 - . + 0x0
	.align	3
	.align	2
L240:
	.long	L243 - . + 0x1
	.long	0xf84518
	.long	L245 - . + 0x0
	.long	0x1480960
	.align	2
L239:
	.long	L243 - . + 0x1
	.long	0xf84518
	.long	L245 - . + 0x0
	.long	0x1500968
	.align	2
L238:
	.long	L243 - . + 0x1
	.long	0xf84518
	.long	L245 - . + 0x0
	.long	0x1580968
	.align	2
L241:
	.long	L243 - . + 0x1
	.long	0xf84518
	.long	L245 - . + 0x0
	.long	0x1400958
	.align	2
L236:
	.long	L246 - . + 0x0
	.long	0x1004920
	.align	2
L237:
	.long	L247 - . + 0x0
	.long	0xf04108
	.align	2
L235:
	.long	L248 - . + 0x0
	.long	0x1782480
L244:
	.asciz	"test_pretty_print.ml"
L242:
	.asciz	"printf.ml"
	.align	2
L246:
	.long	L244 - . + 0x0
	.asciz	"Test_pretty_print.float_array"
	.align	2
L243:
	.long	L242 - . + 0x0
	.asciz	"Stdlib__Printf.printf"
	.align	2
L247:
	.long	L244 - . + 0x0
	.asciz	"Test_pretty_print.int_array"
	.align	2
L248:
	.long	L244 - . + 0x0
	.asciz	"Test_pretty_print"
	.align	2
L245:
	.long	L244 - . + 0x0
	.asciz	"Test_pretty_print.main"
	.align	3

	# DWARF debugging information
	.section __DWARF,__debug_info,regular,debug
	.byte 0x99,0x02,0x00,0x00,0x05,0x00,0x01,0x08,0x00,0x00,0x00,0x00,0x01,0x74,0x65,0x73
	.byte 0x74,0x5f,0x70,0x72,0x65,0x74,0x74,0x79,0x5f,0x70,0x72,0x69,0x6e,0x74,0x2e,0x6d
	.byte 0x6c,0x00,0x4f,0x43,0x61,0x6d,0x6c,0x20,0x35,0x2e,0x35,0x2e,0x30,0x2b,0x64,0x65
	.byte 0x76,0x30,0x2d,0x32,0x30,0x32,0x35,0x2d,0x30,0x34,0x2d,0x32,0x38,0x00,0x2f,0x55
	.byte 0x73,0x65,0x72,0x73,0x2f,0x6a,0x6f,0x65,0x6c,0x2f,0x57,0x6f,0x72,0x6b,0x2f,0x6f
	.byte 0x63,0x61,0x6d,0x6c,0x2f,0x64,0x77,0x61,0x72,0x66,0x00,0x01,0x80
	.long debug_line_cu_1 - __debug_line_section_base
	.byte 0x09,0x76,0x61,0x6c,0x75,0x65,0x00,0x08,0x01,0x09,0x69,0x6e,0x74,0x00,0x08,0x05
	.byte 0x09,0x66,0x6c,0x6f,0x61,0x74,0x00,0x08,0x04,0x09,0x61,0x64,0x64,0x72,0x00,0x08
	.byte 0x01,0x12,0x74,0x72,0x65,0x65,0x00,0x08,0x13,0x14,0x45,0x6d,0x70,0x74,0x79,0x00
	.byte 0x00,0x15,0x4e,0x6f,0x64,0x65,0x00,0x00,0x16,0x76,0x61,0x6c,0x75,0x65,0x00,0x5d
	.byte 0x00,0x00,0x00,0x08,0x16,0x6c,0x65,0x66,0x74,0x00,0x82,0x00,0x00,0x00,0x10,0x16
	.byte 0x72,0x69,0x67,0x68,0x74,0x00,0x82,0x00,0x00,0x00,0x18,0x00,0x00,0x00,0x12,0x6c
	.byte 0x69,0x73,0x74,0x00,0x08,0x13,0x14,0x5b,0x5d,0x00,0x00,0x15,0x3a,0x3a,0x00,0x00
	.byte 0x16,0x68,0x65,0x61,0x64,0x00,0x5d,0x00,0x00,0x00,0x08,0x16,0x74,0x61,0x69,0x6c
	.byte 0x00,0xbf,0x00,0x00,0x00,0x10,0x00,0x00,0x00,0x12,0x6f,0x70,0x74,0x69,0x6f,0x6e
	.byte 0x00,0x08,0x13,0x14,0x4e,0x6f,0x6e,0x65,0x00,0x00,0x15,0x53,0x6f,0x6d,0x65,0x00
	.byte 0x00,0x16,0x76,0x61,0x6c,0x75,0x65,0x00,0x5d,0x00,0x00,0x00,0x08,0x00,0x00,0x00
	.byte 0x12,0x62,0x6f,0x6f,0x6c,0x00,0x08,0x13,0x14,0x66,0x61,0x6c,0x73,0x65,0x00,0x00
	.byte 0x14,0x74,0x72,0x75,0x65,0x00,0x01,0x00,0x00,0x17,0x54,0x65,0x73,0x74,0x5f,0x70
	.byte 0x72,0x65,0x74,0x74,0x79,0x5f,0x70,0x72,0x69,0x6e,0x74,0x00,0x04,0x6d,0x61,0x69
	.byte 0x6e,0x00,0x63,0x61,0x6d,0x6c,0x54,0x65,0x73,0x74,0x5f,0x70,0x72,0x65,0x74,0x74
	.byte 0x79,0x5f,0x70,0x72,0x69,0x6e,0x74,0x24,0x6d,0x61,0x69,0x6e,0x5f,0x32,0x39,0x31
	.byte 0x00
	.quad _camlTest_pretty_print$main_291
	.quad _camlTest_pretty_print$main_291_end
	.byte 0x01,0x01,0x6d,0x06,0x70,0x61,0x72,0x61,0x6d,0x00,0x66,0x00,0x00,0x00,0x01,0x50
	.byte 0x00,0x00,0x17,0x54,0x65,0x73,0x74,0x5f,0x70,0x72,0x65,0x74,0x74,0x79,0x5f,0x70
	.byte 0x72,0x69,0x6e,0x74,0x00,0x04,0x6d,0x61,0x69,0x6e,0x00,0x63,0x61,0x6d,0x6c,0x54
	.byte 0x65,0x73,0x74,0x5f,0x70,0x72,0x65,0x74,0x74,0x79,0x5f,0x70,0x72,0x69,0x6e,0x74
	.byte 0x24,0x6d,0x61,0x69,0x6e,0x5f,0x32,0x39,0x31,0x00
	.quad _camlTest_pretty_print$main_291
	.quad _camlTest_pretty_print$main_291_end
	.byte 0x01,0x01,0x6d,0x06,0x70,0x61,0x72,0x61,0x6d,0x00,0x66,0x00,0x00,0x00,0x01,0x50
	.byte 0x00,0x04,0x65,0x6e,0x74,0x72,0x79,0x00,0x63,0x61,0x6d,0x6c,0x54,0x65,0x73,0x74
	.byte 0x5f,0x70,0x72,0x65,0x74,0x74,0x79,0x5f,0x70,0x72,0x69,0x6e,0x74,0x24,0x65,0x6e
	.byte 0x74,0x72,0x79,0x00
	.quad _camlTest_pretty_print$entry
	.quad _camlTest_pretty_print$entry_end
	.byte 0x01,0x01,0x6d,0x0c
	.quad _camlTest_pretty_print$entry
	.quad _camlTest_pretty_print$entry_end
	.byte 0x07,0x69,0x6e,0x74,0x5f,0x61,0x72,0x72,0x61,0x79,0x00,0x5d,0x00,0x00,0x00,0x01
	.byte 0x51,0x00,0x0c
	.quad _camlTest_pretty_print$entry
	.quad _camlTest_pretty_print$entry_end
	.byte 0x07,0x66,0x6c,0x6f,0x61,0x74,0x5f,0x61,0x72,0x72,0x61,0x79,0x00,0x5d,0x00,0x00
	.byte 0x00,0x01,0x51,0x00,0x0c
	.quad _camlTest_pretty_print$entry
	.quad _camlTest_pretty_print$entry_end
	.byte 0x07,0x6d,0x61,0x69,0x6e,0x00,0x66,0x00,0x00,0x00,0x01,0x51,0x00,0x0c
	.quad _camlTest_pretty_print$entry
	.quad _camlTest_pretty_print$entry_end
	.byte 0x07,0x2a,0x6d,0x61,0x74,0x63,0x68,0x2a,0x00,0x5d,0x00,0x00,0x00,0x01,0x51,0x00
	.byte 0x00,0x00,0x00
	.section __DWARF,__debug_abbrev,regular,debug
	.byte 0x01,0x11,0x01,0x03,0x08,0x25,0x08,0x1b,0x08,0x13,0x05,0x10,0x17,0x00,0x00,0x02
	.byte 0x11,0x01,0x03,0x08,0x25,0x08,0x1b,0x08,0x13,0x05,0x00,0x00,0x03,0x2e,0x00,0x03
	.byte 0x08,0x6e,0x08,0x11,0x01,0x12,0x01,0x3f,0x19,0x3a,0x0b,0x40,0x18,0x00,0x00,0x04
	.byte 0x2e,0x01,0x03,0x08,0x6e,0x08,0x11,0x01,0x12,0x01,0x3f,0x19,0x3a,0x0b,0x40,0x18
	.byte 0x00,0x00,0x05,0x05,0x00,0x03,0x08,0x02,0x18,0x00,0x00,0x06,0x05,0x00,0x03,0x08
	.byte 0x49,0x13,0x02,0x18,0x00,0x00,0x07,0x34,0x00,0x03,0x08,0x49,0x13,0x02,0x18,0x00
	.byte 0x00,0x08,0x34,0x00,0x03,0x08,0x02,0x18,0x00,0x00,0x09,0x24,0x00,0x03,0x08,0x0b
	.byte 0x0b,0x3e,0x0b,0x00,0x00,0x0a,0x0f,0x00,0x0b,0x0b,0x49,0x13,0x00,0x00,0x0b,0x2e
	.byte 0x01,0x03,0x08,0x49,0x13,0x11,0x01,0x12,0x01,0x3f,0x19,0x3a,0x0b,0x40,0x18,0x00
	.byte 0x00,0x0c,0x0b,0x01,0x11,0x01,0x12,0x01,0x00,0x00,0x0d,0x0b,0x00,0x11,0x01,0x12
	.byte 0x01,0x00,0x00,0x0e,0x05,0x00,0x03,0x08,0x02,0x17,0x00,0x00,0x0f,0x05,0x00,0x03
	.byte 0x08,0x49,0x13,0x02,0x17,0x00,0x00,0x10,0x34,0x00,0x03,0x08,0x49,0x13,0x02,0x17
	.byte 0x00,0x00,0x11,0x34,0x00,0x03,0x08,0x02,0x17,0x00,0x00,0x12,0x13,0x01,0x03,0x08
	.byte 0x0b,0x0b,0x00,0x00,0x13,0x33,0x01,0x00,0x00,0x14,0x19,0x00,0x03,0x08,0x16,0x0b
	.byte 0x00,0x00,0x15,0x19,0x01,0x03,0x08,0x16,0x0b,0x00,0x00,0x16,0x0d,0x00,0x03,0x08
	.byte 0x49,0x13,0x38,0x0b,0x00,0x00,0x17,0x39,0x01,0x03,0x08,0x00,0x00,0x00
	.section __DWARF,__debug_line,regular,debug
__debug_line_section_base:
debug_line_cu_1:
	.byte 0xa3,0x00,0x00,0x00,0x04,0x00,0x56,0x00,0x00,0x00,0x01,0x01,0x01,0xfb,0x0e,0x0d
	.byte 0x00,0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x01,0x2f,0x55,0x73,0x65
	.byte 0x72,0x73,0x2f,0x6a,0x6f,0x65,0x6c,0x2f,0x57,0x6f,0x72,0x6b,0x2f,0x6f,0x63,0x61
	.byte 0x6d,0x6c,0x2f,0x64,0x77,0x61,0x72,0x66,0x00,0x00,0x70,0x72,0x69,0x6e,0x74,0x66
	.byte 0x2e,0x6d,0x6c,0x00,0x00,0x00,0x00,0x74,0x65,0x73,0x74,0x5f,0x70,0x72,0x65,0x74
	.byte 0x74,0x79,0x5f,0x70,0x72,0x69,0x6e,0x74,0x2e,0x6d,0x6c,0x00,0x00,0x00,0x00,0x00
	.byte 0x00,0x09,0x02
	.quad L109
	.byte 0x04,0x01,0x05,0x19,0x03,0x1e,0x01,0x00,0x09,0x02
	.quad L186
	.byte 0x04,0x02,0x05,0x10,0x03,0x7f,0x01,0x00,0x09,0x02
	.quad L193
	.byte 0x05,0x12,0x03,0x02,0x01,0x00,0x09,0x02
	.quad L222
	.byte 0x05,0x09,0x03,0x0f,0x01,0x00,0x01,0x01

