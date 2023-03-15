(func $accumulate_512 (param $acc i32) (param $input i32) (param $secret i32)
  (local $data_vec v128)
  (local $data_key v128)
  (local $data_key_hi v128)
  (local $data_key_lo v128)
  (local $swizz v128)
  (local.set $swizz (v128.const i8x16 8 9 10 11 12 13 14 15 0 1 2 3 4 5 6 7))

  (local.set $data_vec (v128.load (local.get $input)))
  (local.set $data_key (v128.xor (local.get $data_vec) (v128.load (local.get $secret))))
  (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
  (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
  (v128.store
    (local.get $acc)
    (i64x2.add 
      (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
      (i64x2.add 
        (v128.load (local.get $acc)) 
        (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

  (local.set $data_vec (v128.load offset=16 (local.get $input)))
  (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=16 (local.get $secret))))
  (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
  (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
  (v128.store offset=16
    (local.get $acc)
    (i64x2.add 
      (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
      (i64x2.add 
        (v128.load offset=16 (local.get $acc)) 
        (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

  (local.set $data_vec (v128.load offset=32 (local.get $input)))
  (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=32 (local.get $secret))))
  (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
  (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
  (v128.store offset=32
    (local.get $acc)
    (i64x2.add 
      (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
      (i64x2.add 
        (v128.load offset=32 (local.get $acc)) 
        (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

  (local.set $data_vec (v128.load offset=48 (local.get $input)))
  (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=48 (local.get $secret))))
  (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
  (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
  (v128.store offset=48
    (local.get $acc)
    (i64x2.add 
      (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
      (i64x2.add 
        (v128.load offset=48 (local.get $acc)) 
        (i8x16.swizzle (local.get $data_vec) (local.get $swizz))))))