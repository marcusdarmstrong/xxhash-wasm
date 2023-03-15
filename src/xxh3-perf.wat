(module
  (memory (export "mem") 1)

  (data (i32.const 0) "\b8\fe\6c\39\23\a4\4b\be\7c\01\81\2c\f7\21\ad\1c\de\d4\6d\e9\83\90\97\db\72\40\a4\a4\b7\b3\67\1f\cb\79\e6\4e\cc\c0\e5\78\82\5a\d0\7d\cc\ff\72\21\b8\08\46\74\f7\43\24\8e\e0\35\90\e6\81\3a\26\4c\3c\28\52\bb\91\c3\00\cb\88\d0\65\8b\1b\53\2e\a3\71\64\48\97\a2\0d\f9\4e\38\19\ef\46\a9\de\ac\d8\a8\fa\76\3f\e3\9c\34\3f\f9\dc\bb\c7\c7\0b\4f\1d\8a\51\e0\4b\cd\b4\59\31\c8\9f\7e\c9\d9\78\73\64\ea\c5\ac\83\34\d3\eb\c3\c5\81\a0\ff\fa\13\63\eb\17\0d\dd\51\b7\f0\da\49\d3\16\55\26\29\d4\68\9e\2b\16\be\58\7d\47\a1\fc\8f\f8\b8\d1\7a\d0\31\ce\45\cb\3a\8f\95\16\04\28\af\d7\fb\ca\bb\4b\40\7e" align=6)

  (global $kSecret i32 (i32.const 0))

  (global $PRIME32_1 i32 (i32.const 2654435761))
  (global $PRIME32_2 i32 (i32.const 2246822519))
  (global $PRIME32_3 i32 (i32.const 3266489917))
  (global $PRIME32_4 i32 (i32.const 668265263))
  (global $PRIME32_5 i32 (i32.const 374761393))

  (global $PRIME64_1 i64 (i64.const 11400714785074694791))
  (global $PRIME64_2 i64 (i64.const 14029467366897019727))
  (global $PRIME64_3 i64 (i64.const  1609587929392839161))
  (global $PRIME64_4 i64 (i64.const  9650029242287828579))
  (global $PRIME64_5 i64 (i64.const  2870177450012600261))

  (global $swizz_zzyy v128 (v128.const i8x16 8 9 10 11 8 9 10 11 12 13 14 15 12 13 14 15))
  (global $swizz_yyzz v128 (v128.const i8x16 12 13 14 15 12 13 14 15 8 9 10 11 8 9 10 11))

  (global $seedVec (mut v128) (v128.const i64x2 0 0))

;; XXH3_mul128_fold64(lhs, rhs):
;; 	lhs_hi = i64.shr_u(lhs, 32)
;; 	lhs_lo = i64.and(lhs, 0xFFFFFFFF)
;; 	rhs_hi = i64.shr_u(rhs, 32)
;; 	rhs_lo = i64.and(rhs, 0xFFFFFFFF)
;; 
;; 	lo_lo = i64.mul(lhs_lo, rhs_lo)
;; 	hi_lo = i64.mul(lhs_hi, rhs_lo)
;; 
;; 	cross = i64.add(
;;     i64.add(
;;       i64.shr_u(lo_lo, 32),
;;       i64.and(hi_lo, 0xFFFFFFFF)
;;     ),
;;     i64.mul(lhs_lo, rhs_hi)
;;   )
;; 
;; 	return i64.xor(
;;     i64.add(
;;       i64.add(i64.shr_u(hi_lo, 32), i64.shr_u(cross, 32)),
;;       i64.mul(lhs_hi, rhs_hi)
;;     ),
;;     i64.or(i64.shl(cross, 32), i64.and(lo_lo, 0xFFFFFFFF))
;;   )
;;(func $XXH3_mul128_fold64 (param $lhs i64) (param $rhs i64) (result i64)
;;  (local $lhs_hi i64)
;;  (local $lhs_lo i64)
;;  (local $rhs_hi i64)
;;  (local $rhs_lo i64)
;;  (local $lo_lo i64)
;;  (local $hi_lo i64)
;;  (local $cross i64)
;;  (local.set $lhs_hi (i64.shr_u (local.get $lhs) (i64.const 32)))
;;  (local.set $lhs_lo (i64.and (local.get $lhs) (i64.const 0xFFFFFFFF)))
;;  (local.set $rhs_hi (i64.shr_u (local.get $rhs) (i64.const 32)))
;;  (local.set $rhs_lo (i64.and (local.get $rhs) (i64.const 0xFFFFFFFF)))
;;  (local.set $lo_lo (i64.mul (local.get $lhs_lo) (local.get $rhs_lo)))
;;  (local.set $hi_lo (i64.mul (local.get $lhs_hi) (local.get $rhs_lo)))
;;  (local.set $cross 
;;    (i64.add 
;;      (i64.add 
;;        (i64.shr_u (local.get $lo_lo) (i64.const 32))
;;        (i64.and (local.get $hi_lo) (i64.const 0xFFFFFFFF)))
;;      (i64.mul (local.get $lhs_lo) (local.get $rhs_hi))))
;;  (i64.xor 
;;    (i64.add 
;;      (i64.add 
;;        (i64.shr_u (local.get $hi_lo) (i64.const 32))
;;        (i64.shr_u (local.get $cross) (i64.const 32)))
;;      (i64.mul (local.get $lhs_hi) (local.get $rhs_hi)))
;;    (i64.or 
;;      (i64.shl (local.get $cross) (i64.const 32)) 
;;      (i64.and (local.get $lo_lo) (i64.const 0xFFFFFFFF)))))

(func $XXH3_mul128_fold64_vector (param $lhs i64) (param $rhs i64) (result i64)
  (local $r_hi v128)
  (local $r_lo v128)
  (local $left v128)
  (local $r_his v128)
  (local $r_los v128)
  (local $r_los_his v128)
  (local $r_los_los v128)
  (local $cross i64)
  (local $upper i64)
  (local $lower i64)

  ;;(local.set $r_hi 
  ;;  (i64x2.splat (i64.shr_u (local.get $rhs) (i64.const 32))))
  ;;(local.set $r_lo 
  ;;  ;;(i64x2.splat (local.get $rhs)))
  ;;  (i64x2.splat (i64.and (local.get $rhs) (i64.const 0xFFFFFFFF))))
  ;;(local.set $left 
  ;;  (i64x2.replace_lane 1 
  ;;    ;;(i64x2.splat (local.get $lhs))
  ;;    (i64x2.splat (i64.and (local.get $lhs) (i64.const 0xFFFFFFFF)))
  ;;    (i64.shr_u (local.get $lhs) (i64.const 32))))

  (local.set $left (i64x2.splat (local.get $lhs)))
  (local.set $r_hi (i32x4.splat (i32.wrap_i64 (i64.shr_u (local.get $rhs) (i64.const 32)))))
  (local.set $r_lo (i32x4.splat (i32.wrap_i64 (local.get $rhs))))

  ;;(local.set $r_his 
  ;;  (i64x2.mul (local.get $left) (local.get $r_hi)))
  ;;(local.set $r_los
  ;;  (i64x2.mul (local.get $left) (local.get $r_lo)))

  (local.set $r_his 
    (i64x2.extmul_low_i32x4_u (local.get $left) (local.get $r_hi)))
  (local.set $r_los
    (i64x2.extmul_low_i32x4_u (local.get $left) (local.get $r_lo)))

  (local.set $r_los_his (i64x2.shr_u (local.get $r_los) (i32.const 32)))
  (local.set $r_los_los 
    (v128.and 
      (local.get $r_los)
      (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))

  (local.set $cross
    (i64.add 
      ;; r_los_his[0] = lo_lo >> 32
      (i64x2.extract_lane 0 (local.get $r_los_his))
      (i64.add 
        ;; r_los_los[1] = hi_lo & 0xFFFFFFFF
        (i64x2.extract_lane 1 (local.get $r_los_los))
        ;; r_his[0] = lo_hi
        (i64x2.extract_lane 0 (local.get $r_his)))))
  (local.set $upper
    (i64.add 
      ;; r_los_his[1] = hi_lo >> 32
      (i64x2.extract_lane 1 (local.get $r_los_his))
      (i64.add 
        (i64.shr_u (local.get $cross) (i64.const 32))
        ;; r_his[1] = hi_hi
        (i64x2.extract_lane 1 (local.get $r_his)))))
  (local.set $lower 
    (i64.or 
      (i64.shl (local.get $cross) (i64.const 32))
      ;; r_los_los[0] = lo_lo & 0xFFFFFFFF
      (i64x2.extract_lane 0 (local.get $r_los_los))))
  (i64.xor (local.get $lower) (local.get $upper)))

(func $XXH3_mul128_fold64 (param $lhs i64) (param $rhs i64) (result i64)
  (local $lhs_hi i64)
  (local $lhs_lo i64)
  (local $rhs_hi i64)
  (local $rhs_lo i64)
  (local $lo_lo i64)
  (local $hi_lo i64)
  (local $cross i64)
  (local.set $lhs_hi (i64.shr_u (local.get $lhs) (i64.const 32)))
  (local.set $lhs_lo (i64.and (local.get $lhs) (i64.const 0xFFFFFFFF)))
  (local.set $rhs_hi (i64.shr_u (local.get $rhs) (i64.const 32)))
  (local.set $rhs_lo (i64.and (local.get $rhs) (i64.const 0xFFFFFFFF)))
  (local.set $lo_lo (i64.mul (local.get $lhs_lo) (local.get $rhs_lo)))
  (local.set $hi_lo (i64.mul (local.get $lhs_hi) (local.get $rhs_lo)))
  (local.set $cross 
    (i64.add 
      (i64.add 
        (i64.shr_u (local.get $lo_lo) (i64.const 32))
        (i64.and (local.get $hi_lo) (i64.const 0xFFFFFFFF)))
      (i64.mul (local.get $lhs_lo) (local.get $rhs_hi))))
  (i64.xor 
    (i64.add 
      (i64.add 
        (i64.shr_u (local.get $hi_lo) (i64.const 32))
        (i64.shr_u (local.get $cross) (i64.const 32)))
      (i64.mul (local.get $lhs_hi) (local.get $rhs_hi)))
    (i64.or 
      (i64.shl (local.get $cross) (i64.const 32)) 
      (i64.and (local.get $lo_lo) (i64.const 0xFFFFFFFF)))))

(func $XXH_xorshift (param $v64 i64) (param $shift i32) (result i64)
	(i64.xor (local.get $v64) (i64.shr_u (local.get $v64) (i64.extend_i32_u (local.get $shift)))))

;; XXH64_avalanche(hash):
;;     hash = i64.xor(hash, i64.shr_u(hash, 33))
;;     hash = i64.mul(hash, XXH_PRIME64_2)
;;     hash = i64.xor(hash, i64.shr_u(hash, 29))
;;     hash = i64.mul(hash, XXH_PRIME64_3)
;;     return i64.xor(hash, i64.shr_u(hash, 32))
(func $XXH64_avalanche (param $hash i64) (result i64)
  (local.set $hash 
    (i64.mul 
      (i64.xor (local.get $hash) (i64.shr_u (local.get $hash) (i64.const 33))) 
      (global.get $PRIME64_2)))
  (local.set $hash 
    (i64.mul 
      (i64.xor (local.get $hash) (i64.shr_u (local.get $hash) (i64.const 29))) 
      (global.get $PRIME64_3)))
  (i64.xor (local.get $hash) (i64.shr_u (local.get $hash) (i64.const 32))))


;; XXH3_avalanche(h64):
;; 	return XXH_xorshift(
;; 		i64.mul(XXH_xorshift(h64, 37), 0x165667919E3779F9),
;; 	 	32
;; 	 );
(func $XXH3_avalanche (param $h64 i64) (result i64)
  (call $XXH_xorshift 
    (i64.mul 
      (call $XXH_xorshift 
        (local.get $h64)
        (i32.const 37))
      (i64.const 0x165667919E3779F9))
    (i32.const 32)))
 
;; XXH3_64bits_withSeed(input, len, seed64):
;; 	if (len <= 16)
;;         return XXH3_len_0to16_64b(input, len, XXH3_kSecret, seed64);
;;     if (len <= 128)
;;         return XXH3_len_17to128_64b(input, len, XXH3_kSecret, 192, seed64);
;;     if (len <= 240)
;;         return XXH3_len_129to240_64b(input, len, XXH3_kSecret, 192, seed64);
;; 
;;     if (seed64 == 0)
;;     	secret = XXH3_kSecret
;;     	secretSize = 192
;;     else 
;;     	// TODO
;; 
;;     // Alloc 8*8 at start of linear memory, this is acc.
;;     // init acc...
;;     acc = 64
;;     memory.init(acc, XXH3_INIT_ACC, 64)
;; 	XXH3_hashLong_internal_loop(acc, input, len, secret, secretSize)
;; 
;; 	return XXH3_mergeAccs(acc, i32.add(secret + 11), i64.mul(i64.extend_i32_u(len), XXH_PRIME64_1));
;; XXH3_INIT_ACC { XXH_PRIME32_3, XXH_PRIME64_1, XXH_PRIME64_2, XXH_PRIME64_3, XXH_PRIME64_4, XXH_PRIME32_2, XXH_PRIME64_5, XXH_PRIME32_1 }
(func (export "xxh3") (param $input i32) (param $len i32) (param $seed i64) (result i64)
  (local $secret i32)
  (local $secretSize i32)

  (local $acc_lane0 v128)
  (local $acc_lane1 v128)
  (local $acc_lane2 v128)
  (local $acc_lane3 v128)

  ;; XXH3_mergeAccs
  (local $result64 i64)

  ;; XXH3_hashLong_internal_loop
  (local $nbStripesPerBlock i32)
  (local $block_len i32)
  (local $nb_blocks i32)
  (local $n i32)

  ;; accumulate
  (local $s i32)

  ;; scrambleAcc
  (local $prime32 v128)
  (local $scrambleSecret i32)

  ;; accumulate_512
  (local $accumulate512Input i32)
  (local $accumulate512Secret i32)
  (local $data_vec v128)
  (local $data_key v128)
  (local $data_key_hi v128)
  (local $data_key_lo v128)
  (local $swizz v128)

  (global.set $seedVec (i64x2.replace_lane 1 (i64x2.splat (local.get $seed)) (i64.sub (i64.const 0) (local.get $seed))))

  (if (result i64) (i32.le_u (local.get $len) (i32.const 16)) 
    (then 
      (call $XXH3_len_0to16_64b (local.get $input) (local.get $len) (global.get $kSecret) (local.get $seed)))
    (else
      (if (result i64) (i32.le_u (local.get $len) (i32.const 128)) 
        (then
          (call $XXH3_len_17to128_64b (local.get $input) (local.get $len) (global.get $kSecret) (i32.const 192) (local.get $seed)))
        (else
          (if (result i64) (i32.le_u (local.get $len) (i32.const 240))
            (then
              (call $XXH3_len_129to240_64b (local.get $input) (local.get $len) (global.get $kSecret) (i32.const 192) (local.get $seed)))
            (else 
              (if (i64.eq (local.get $seed) (i64.const 0))
                (then
                  (local.set $secret (global.get $kSecret))
                  (local.set $secretSize (i32.const 192))
                  (local.set $nbStripesPerBlock (i32.const 16))
                  (local.set $block_len (i32.const 1024))
                  (local.set $nb_blocks (i32.shr_u (i32.sub (local.get $len) (i32.const 1)) (i32.const 10))))
                (else
                  ;; TODO: generate a proper secret
                  (local.set $nbStripesPerBlock (i32.shr_s (i32.sub (local.get $secretSize) (i32.const 64)) (i32.const 3)))
                  (local.set $block_len (i32.shl (local.get $nbStripesPerBlock) (i32.const 6)))
                  (local.set $nb_blocks (i32.div_u (i32.sub (local.get $len) (i32.const 1)) (local.get $block_len)))))

              ;; $PRIME32_3, $PRIME64_1
              (local.set $acc_lane0 (v128.const i64x2 3266489917 11400714785074694791))
              ;; $PRIME64_2, $PRIME64_3
              (local.set $acc_lane1 (v128.const i64x2 14029467366897019727 1609587929392839161))
              ;; $PRIME64_4, $PRIME32_2
              (local.set $acc_lane2 (v128.const i64x2 9650029242287828579 2246822519))
              ;; $PRIME64_5, $PRIME32_1
              (local.set $acc_lane3 (v128.const i64x2 2870177450012600261 2654435761))

              ;; For accumulate512
              ;; TODO: hoist?
              (local.set $swizz (v128.const i8x16 8 9 10 11 12 13 14 15 0 1 2 3 4 5 6 7))

              ;; XXH3_hashLong_internal_loop:
              (local.set $n (i32.const 0))
              (block $exit
                (loop $l
                  (br_if $exit (i32.ge_u (local.get $n) (local.get $nb_blocks)))

                  ;; accumulate:
                  (local.set $s (i32.const 0))
                  (block $exit2
                    (loop $l2
                      (br_if $exit2 (i32.ge_u (local.get $s) (local.get $nbStripesPerBlock)))

                      ;; accumulate512
                      (local.set $accumulate512Input 
                        (i32.add 
                          (i32.add 
                            (local.get $input)
                            (i32.mul (local.get $n) (local.get $block_len)))
                          (i32.shl (local.get $s) (i32.const 6))))
                      (local.set $accumulate512Secret (i32.add (local.get $secret) (i32.shl (local.get $s) (i32.const 3))))

                      (local.set $data_vec (v128.load (local.get $accumulate512Input)))
                      (local.set $data_key (v128.xor (local.get $data_vec) (v128.load (local.get $accumulate512Secret))))
                      (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
                      (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
                      (local.set $acc_lane0
                        (i64x2.add 
                          (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                          (i64x2.add 
                            (local.get $acc_lane0) 
                            (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

                      (local.set $data_vec (v128.load offset=16 (local.get $accumulate512Input)))
                      (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=16 (local.get $accumulate512Secret))))
                      (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
                      (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
                      (local.set $acc_lane1
                        (i64x2.add 
                          (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                          (i64x2.add 
                            (local.get $acc_lane1)
                            (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

                      (local.set $data_vec (v128.load offset=32 (local.get $accumulate512Input)))
                      (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=32 (local.get $accumulate512Secret))))
                      (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
                      (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
                      (local.set $acc_lane2
                        (i64x2.add 
                          (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                          (i64x2.add 
                            (local.get $acc_lane2)
                            (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

                      (local.set $data_vec (v128.load offset=48 (local.get $accumulate512Input)))
                      (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=48 (local.get $accumulate512Secret))))
                      (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
                      (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
                      (local.set $acc_lane3
                        (i64x2.add 
                          (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                          (i64x2.add 
                            (local.get $acc_lane3)
                            (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))
                      ;; acumulate512 end

                      (local.set $s (i32.add (local.get $s) (i32.const 1)))
                      (br $l2)))
                      ;; accumulate end

                  ;; scrambleAcc
                  (local.set $scrambleSecret 
                    (i32.sub 
                      (i32.add (local.get $secret) (local.get $secretSize))
                      (i32.const 64)))
                  ;;(local.set $prime32 (i64x2.splat (i64.extend_i32_u (global.get $PRIME32_1))))
                  ;; PRIME32_1
                  (local.set $prime32 (v128.const i64x2 2654435761 2654435761))
                  (local.set $acc_lane0
                    (i64x2.mul 
                      (v128.xor 
                        (v128.xor 
                          (local.get $acc_lane0) 
                          (i64x2.shr_u (local.get $acc_lane0) (i32.const 47)))
                        (v128.load offset=0 (local.get $scrambleSecret)))
                      (local.get $prime32)))

                  (local.set $acc_lane1
                    (i64x2.mul 
                      (v128.xor 
                        (v128.xor 
                          (local.get $acc_lane1) 
                          (i64x2.shr_u (local.get $acc_lane1) (i32.const 47)))
                        (v128.load offset=16 (local.get $scrambleSecret)))
                      (local.get $prime32)))

                  (local.set $acc_lane2
                    (i64x2.mul 
                      (v128.xor 
                        (v128.xor 
                          (local.get $acc_lane2) 
                          (i64x2.shr_u (local.get $acc_lane2) (i32.const 47)))
                        (v128.load offset=32 (local.get $scrambleSecret)))
                      (local.get $prime32)))

                  (local.set $acc_lane3
                    (i64x2.mul 
                      (v128.xor 
                        (v128.xor 
                          (local.get $acc_lane3) 
                          (i64x2.shr_u (local.get $acc_lane3) (i32.const 47)))
                        (v128.load offset=48 (local.get $scrambleSecret)))
                      (local.get $prime32)))
                  ;; end scrambleAcc

                  (local.set $n (i32.add (local.get $n) (i32.const 1)))
                  (br $l)))

              ;; accumulate:
              ;; Mutating this local since it's used in the loop and not needed again.
              (local.set $nbStripesPerBlock 
                (i32.shr_u
                  (i32.sub 
                    (i32.sub (local.get $len) (i32.const 1))
                    (i32.mul (local.get $block_len) (local.get $nb_blocks)))
                  (i32.const 6)))
              (local.set $s (i32.const 0))
              (block $exit3
                (loop $l3
                  (br_if $exit3 (i32.ge_u (local.get $s) (local.get $nbStripesPerBlock)))

                  ;; accumulate512
                  (local.set $accumulate512Input
                    (i32.add 
                      (i32.add 
                        (local.get $input)
                        (i32.mul (local.get $nb_blocks) (local.get $block_len)))
                      (i32.shl (local.get $s) (i32.const 6))))
                  (local.set $accumulate512Secret (i32.add (local.get $secret) (i32.shl (local.get $s) (i32.const 3))))

                  (local.set $data_vec (v128.load (local.get $accumulate512Input)))
                  (local.set $data_key (v128.xor (local.get $data_vec) (v128.load (local.get $accumulate512Secret))))
                  (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
                  (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
                  (local.set $acc_lane0
                    (i64x2.add 
                      (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                      (i64x2.add 
                        (local.get $acc_lane0)
                        (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

                  (local.set $data_vec (v128.load offset=16 (local.get $accumulate512Input)))
                  (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=16 (local.get $accumulate512Secret))))
                  (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
                  (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
                  (local.set $acc_lane1
                    (i64x2.add 
                      (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                      (i64x2.add 
                        (local.get $acc_lane1)
                        (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

                  (local.set $data_vec (v128.load offset=32 (local.get $accumulate512Input)))
                  (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=32 (local.get $accumulate512Secret))))
                  (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
                  (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
                  (local.set $acc_lane2
                    (i64x2.add 
                      (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                      (i64x2.add 
                        (local.get $acc_lane2)
                        (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

                  (local.set $data_vec (v128.load offset=48 (local.get $accumulate512Input)))
                  (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=48 (local.get $accumulate512Secret))))
                  (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
                  (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
                  (local.set $acc_lane3
                    (i64x2.add 
                      (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                      (i64x2.add 
                        (local.get $acc_lane3)
                        (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))
                  ;; end accumulate512

                  (local.set $s (i32.add (local.get $s) (i32.const 1)))
                  (br $l3)))
                  ;; end accumulate

              ;; accumulate512
              (local.set $accumulate512Input (i32.sub (i32.add (local.get $input) (local.get $len)) (i32.const 64)))
              (local.set $accumulate512Secret (i32.sub (i32.add (local.get $secret) (local.get $secretSize)) (i32.const 71)))

              (local.set $data_vec (v128.load (local.get $accumulate512Input)))
              (local.set $data_key (v128.xor (local.get $data_vec) (v128.load (local.get $accumulate512Secret))))
              (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
              (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
              (local.set $acc_lane0
                (i64x2.add 
                  (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                  (i64x2.add 
                    (local.get $acc_lane0)
                    (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

              (local.set $data_vec (v128.load offset=16 (local.get $accumulate512Input)))
              (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=16 (local.get $accumulate512Secret))))
              (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
              (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
              (local.set $acc_lane1
                (i64x2.add 
                  (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                  (i64x2.add 
                    (local.get $acc_lane1)
                    (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

              (local.set $data_vec (v128.load offset=32 (local.get $accumulate512Input)))
              (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=32 (local.get $accumulate512Secret))))
              (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
              (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
              (local.set $acc_lane2
                (i64x2.add 
                  (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                  (i64x2.add 
                    (local.get $acc_lane2)
                    (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))

              (local.set $data_vec (v128.load offset=48 (local.get $accumulate512Input)))
              (local.set $data_key (v128.xor (local.get $data_vec) (v128.load offset=48 (local.get $accumulate512Secret))))
              (local.set $data_key_hi (i64x2.shr_u (local.get $data_key) (i32.const 32)))
              (local.set $data_key_lo (v128.and (local.get $data_key) (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))
              (local.set $acc_lane3
                (i64x2.add 
                  (i64x2.mul (local.get $data_key_lo) (local.get $data_key_hi)) 
                  (i64x2.add 
                    (local.get $acc_lane3)
                    (i8x16.swizzle (local.get $data_vec) (local.get $swizz)))))
              ;; end accumulate512

              ;; XXH3_mergeAccs:
              (local.set $result64 
                (i64.add 
                  (i64.mul (i64.extend_i32_u (local.get $len)) (global.get $PRIME64_1))
                  (call $XXH3_mul128_fold64
                    (i64.xor 
                      (i64x2.extract_lane 0 (local.get $acc_lane0))
                      (i64.load offset=11 (local.get $secret)))
                    (i64.xor 
                      (i64x2.extract_lane 1 (local.get $acc_lane0))
                      (i64.load offset=19 (local.get $secret))))))

              (local.set $result64 
                (i64.add 
                  (local.get $result64) 
                  (call $XXH3_mul128_fold64
                    (i64.xor 
                      (i64x2.extract_lane 0 (local.get $acc_lane1))
                      (i64.load offset=27 (local.get $secret)))
                    (i64.xor 
                      (i64x2.extract_lane 1 (local.get $acc_lane1))
                      (i64.load offset=35 (local.get $secret))))))

              (local.set $result64 
                (i64.add 
                  (local.get $result64) 
                  (call $XXH3_mul128_fold64
                    (i64.xor 
                      (i64x2.extract_lane 0 (local.get $acc_lane2))
                      (i64.load offset=43 (local.get $secret)))
                    (i64.xor 
                      (i64x2.extract_lane 1 (local.get $acc_lane2))
                      (i64.load offset=51 (local.get $secret))))))

              (local.set $result64 
                (i64.add 
                  (local.get $result64) 
                  (call $XXH3_mul128_fold64
                    (i64.xor 
                      (i64x2.extract_lane 0 (local.get $acc_lane3))
                      (i64.load offset=59 (local.get $secret)))
                    (i64.xor 
                      (i64x2.extract_lane 1 (local.get $acc_lane3))
                      (i64.load offset=67 (local.get $secret))))))

              (call $XXH3_avalanche (local.get $result64)))))))))

;; XXH_swap32(x):
;;   return i32.or(
;;   	i32.and(i32.shl(x, 24), 0xff000000),
;;   	i32.or(
;;       i32.and(i32.shl(x, 8), 0x00ff0000),
;;       i32.or(
;;       	i32.and(i32.shr_u(x, 8), 0x0000ff00),
;;       	i32.and(i32.shr_u(x, 24), 0x000000ff)
;;       )
;;     )
;;   )
(func $XXH_swap32 (param $x i32) (result i32) 
  (i32.or (i32.and (i32.shl (local.get $x) (i32.const 24)) (i32.const 0xff000000))
    (i32.or (i32.and (i32.shl (local.get $x) (i32.const 8)) (i32.const 0x00ff0000))
      (i32.or (i32.and (i32.shr_u (local.get $x) (i32.const 8)) (i32.const 0x0000ff00))
        (i32.and (i32.shr_u (local.get $x) (i32.const 24)) (i32.const 0x000000ff))))))

;; XXH_swap64(x):
;;  return i64.or(
;;   	i64.or(
;;     	i64.or(
;; 	    	i64.or(
;; 		    	i64.or(
;; 	        	i64.or(
;;   			    	i64.or(
;;   			    		i64.and(i64.shl(x, 56), 0xff00000000000000),
;;   			    		i64.and(i64.shl(x, 40), 0x00ff000000000000)
;;   			    	),
;;   		            i64.and(i64.shl(x, 24), 0x0000ff0000000000)
;;   		        ),
;; 	            i64.and(i64.shl(x, 8), 0x000000ff00000000)
;; 		        ),
;; 	          i64.and(i64.shr_u(x, 8), 0x00000000ff000000)
;; 	        ),
;;           i64.and(i64.shr_u(x, 24), 0x0000000000ff0000)
;;         ),
;;       i64.and(i64.shr_u(x, 40), 0x000000000000ff00)
;;     ),
;;     i64.and(i64.shr_u(x, 56), 0x00000000000000ff)
;;   )
(func $XXH_swap64 (param $x i64) (result i64)
  (i64.or 
    (i64.or 
      (i64.or 
        (i64.or 
          (i64.or 
            (i64.or 
              (i64.or 
                (i64.and (i64.shl (local.get $x) (i64.const 56)) (i64.const 0xff00000000000000))
                (i64.and (i64.shl (local.get $x) (i64.const 40)) (i64.const 0x00ff000000000000)))
              (i64.and (i64.shl (local.get $x) (i64.const 24)) (i64.const 0x0000ff0000000000)))
            (i64.and (i64.shl (local.get $x) (i64.const 8)) (i64.const 0x000000ff00000000)))
          (i64.and (i64.shr_u (local.get $x) (i64.const 8)) (i64.const 0x00000000ff000000)))
        (i64.and (i64.shr_u (local.get $x) (i64.const 24)) (i64.const 0x0000000000ff0000)))
      (i64.and (i64.shr_u (local.get $x) (i64.const 40)) (i64.const 0x000000000000ff00)))
    (i64.and (i64.shr_u (local.get $x) (i64.const 56)) (i64.const 0x00000000000000ff))))

;; XXH3_mix16B(input, secret, seed64):
;; 	return XXH3_mul128_fold64(
;; 		i64.xor(i64.load(input), i64.add(i64.load(secret), seed64),
;; 		i64.xor(
;; 			i64.load(i32.add(input, 8)),
;; 			i64.sub(i64.load(i32.add(secret, 8)), seed64)
;; 		)
;; 	)
(func $XXH3_mix16B_scalar (param $input i32) (param $secret i32) (param $seed64 i64) (result i64)
  (call $XXH3_mul128_fold64
    (i64.xor (i64.load (local.get $input)) (i64.add (i64.load (local.get $secret)) (local.get $seed64)))
    (i64.xor 
      (i64.load offset=8 (local.get $input)) 
      (i64.sub (i64.load offset=8 (local.get $secret)) (local.get $seed64)))))

(func $XXH3_mix16B (param $input i32) (param $secret i32) (param $seed i64) (result i64)
  ;;(local $seedVec v128)
  (local $sides v128)

  (local $r_his v128)
  (local $r_los v128)
  (local $r_los_his v128)
  (local $r_los_los v128)
  (local $cross i64)
  (local $upper i64)
  (local $lower i64)

  ;;(local.set $seedVec 
  ;;  (i64x2.replace_lane 1 (i64x2.splat (local.get $seed)) (i64.sub (i64.const 0) (local.get $seed))))

  (local.set $sides (v128.xor 
    (v128.load (local.get $input))
    (i64x2.add (v128.load (local.get $secret)) (global.get $seedVec))))
    
  (local.set $r_his 
    (i64x2.extmul_low_i32x4_u
      (local.get $sides)
      (i8x16.swizzle (local.get $sides) (global.get $swizz_yyzz))))
  (local.set $r_los
    (i64x2.extmul_low_i32x4_u
      (local.get $sides)
      (i8x16.swizzle (local.get $sides) (global.get $swizz_zzyy))))

  (local.set $r_los_his (i64x2.shr_u (local.get $r_los) (i32.const 32)))
  (local.set $r_los_los 
    (v128.and 
      (local.get $r_los)
      (v128.const i64x2 0xFFFFFFFF 0xFFFFFFFF)))

  (local.set $cross
    (i64.add 
      ;; r_los_his[0] = lo_lo >> 32
      (i64x2.extract_lane 0 (local.get $r_los_his))
      (i64.add 
        ;; r_los_los[1] = hi_lo & 0xFFFFFFFF
        (i64x2.extract_lane 1 (local.get $r_los_los))
        ;; r_his[0] = lo_hi
        (i64x2.extract_lane 0 (local.get $r_his)))))
  (local.set $upper
    (i64.add 
      ;; r_los_his[1] = hi_lo >> 32
      (i64x2.extract_lane 1 (local.get $r_los_his))
      (i64.add 
        (i64.shr_u (local.get $cross) (i64.const 32))
        ;; r_his[1] = hi_hi
        (i64x2.extract_lane 1 (local.get $r_his)))))
  (local.set $lower 
    (i64.or 
      (i64.shl (local.get $cross) (i64.const 32))
      ;; r_los_los[0] = lo_lo & 0xFFFFFFFF
      (i64x2.extract_lane 0 (local.get $r_los_los))))
  (i64.xor (local.get $lower) (local.get $upper))
)


;; XXH3_len_0to16_64b(input, len, secret, seed):
;; 	if (len >  8)
;; 		return XXH3_len_9to16_64b(input, len, secret, seed)
;;  if (len >= 4)
;;    return XXH3_len_4to8_64b(input, len, secret, seed)
;;  if (len > 0)
;;    return XXH3_len_1to3_64b(input, len, secret, seed)
;;  return XXH64_avalanche(
;;    i64.xor(
;;      seed,
;;     	i64.xor(
;;     		i64.load(i32.add(secret, 56)),
;;     		i64.load(i32.add(secret, 64))
;;     	)
;;    )
;;  )
(func $XXH3_len_0to16_64b (param $input i32) (param $len i32) (param $secret i32) (param $seed i64) (result i64)
  (if (result i64) (i32.gt_u (local.get $len) (i32.const 8))
    (then
      (call $XXH3_len_9to16_64b (local.get $input) (local.get $len) (local.get $secret) (local.get $seed)))
    (else
      (if (result i64) (i32.ge_u (local.get $len) (i32.const 4))
        (then
          (call $XXH3_len_4to8_64b (local.get $input) (local.get $len) (local.get $secret) (local.get $seed)))
        (else
          (if (result i64) (i32.gt_u (local.get $len) (i32.const 0))
            (then
              (call $XXH3_len_1to3_64b (local.get $input) (local.get $len) (local.get $secret) (local.get $seed))) 
            (else
              (call $XXH64_avalanche 
                (i64.xor 
                  (local.get $seed) 
                  (i64.xor 
                    (i64.load offset=56 (local.get $secret))
                    (i64.load offset=64 (local.get $secret))))))))))))

;; XXH3_len_1to3_64b(input, len, secret, seed):
;;     return XXH64_avalanche(
;;     	i64.xor(
;;     		i64.extend_i32_u(
;; 	    		i32.or(
;; 			    	i32.shl(i32.load8_u(input), 16),
;; 			    	i32.or(
;; 			    		i32.shl(
;; 			    			i32.load8_u(
;; 			    				i32.add(input, i32.shr_u(len, 1))
;; 			    			),
;; 			    			24
;; 			    		),
;; 			    		i32.or(
;; 			    			i32.load8_u(
;; 			    				i32.add(input, i32.sub(len, 1))
;; 			    			),
;; 			    			i32.shl(len, 8)
;; 			    		)
;; 			        )
;; 			    )
;; 	    	),
;;     		i64.add(
;;     			i64.extend_i32_u(
;; 	    			i32.xor(
;; 	    				i32.load(secret),
;; 	    				i32.load(i32.add(secret, 4))
;; 	    			),
;; 	    		),
;;     			seed
;;     		)
;;     	)
;;     )
(func $XXH3_len_1to3_64b (param $input i32) (param $len i32) (param $secret i32) (param $seed i64) (result i64)
  (call $XXH64_avalanche
    (i64.xor
      (i64.extend_i32_u 
        (i32.or 
          (i32.shl (i32.load8_u (local.get $input)) (i32.const 16))
          (i32.or 
            (i32.shl (i32.load8_u (i32.add (local.get $input) (i32.shr_u (local.get $len) (i32.const 1)))) (i32.const 24))
            (i32.or (i32.load8_u (i32.add (local.get $input) (i32.sub (local.get $len) (i32.const 1)))) (i32.shl (local.get $len) (i32.const 8))))))
      (i64.add
        (i64.extend_i32_u 
          (i32.xor 
            (i32.load (local.get $secret))
            (i32.load offset=4 (local.get $secret))))
        (local.get $seed)))))

;; XXH3_len_4to8_64b(input, len, secret, seed):
;;   return XXH3_rrmxmx(
;;   	i64.xor(
;;   		i64.add(
;; 	    	i32.load(i32.sub(i32.add(input, len), 4)),
;; 	    	i64.shl(i64.extend_i32_u(i32.load(input)), 32)
;; 	    ),
;;     	i64.sub(
;; 	    	i64.xor(
;; 	    		i64.load(i32.add(secret, 8)),
;; 	    		i64.load(i32.add(secret, 16))
;; 	    	),
;; 	    	i64.xor(
;; 	    		seed,
;; 	    		i64.shl(i64.extend_i32_u(XXH_swap32(i32.wrap_i64(seed))), 32)
;; 	    	)
;;     	)
;;   	),
;;   	len
;;   );
(func $XXH3_len_4to8_64b (param $input i32) (param $len i32) (param $secret i32) (param $seed i64) (result i64)
  (call $XXH3_rrmxmx
    (i64.xor
      (i64.add
        (i64.extend_i32_u (i32.load (i32.sub (i32.add (local.get $input) (local.get $len)) (i32.const 4))))
        (i64.shl (i64.extend_i32_u (i32.load (local.get $input))) (i64.const 32)))
      (i64.sub
        (i64.xor (i64.load offset=8 (local.get $secret)) (i64.load offset=16 (local.get $secret)))
        (i64.xor (local.get $seed) (i64.shl (i64.extend_i32_u (call $XXH_swap32 (i32.wrap_i64 (local.get $seed)))) (i64.const 32)))))
    (local.get $len)))


;; u64 XXH3_rrmxmx(u64 h64, u32 len):
;;     h64 = (h64 ^ (XXH_rotl64(h64, 49) ^ XXH_rotl64(h64, 24))) * 0x9FB21C651E98DF25ULL
;;     return XXH_xorshift((h64 ^ ((h64 >> 35) + len)) * 0x9FB21C651E98DF25ULL, 28)
(func $XXH3_rrmxmx (param $h64 i64) (param $len i32) (result i64)
  (local.set $h64 
    (i64.mul 
      (i64.const 0x9FB21C651E98DF25)
      (i64.xor 
        (local.get $h64)
        (i64.xor
          (i64.rotl (local.get $h64) (i64.const 49))
          (i64.rotl (local.get $h64) (i64.const 24))))))
  (call $XXH_xorshift
    (i64.mul 
      (i64.const 0x9FB21C651E98DF25)
      (i64.xor
        (local.get $h64)
        (i64.add
          (i64.extend_i32_u (local.get $len))
          (i64.shr_u (local.get $h64) (i64.const 35)))))
    (i32.const 28)))

;; XXH3_len_9to16_64b(input, len, secret, seed):
;;   u64 input_lo = i64.xor(
;;     	i64.load(input),
;;     	i64.add(
;; 			  i64.xor(
;; 				  i64.load(i32.add(secret, 24)),
;; 				  i64.load(i32.add(secret, 32))
;; 			  ),
;; 			  seed
;; 		  )
;; 	)
;; 	u64 input_hi = i64.xor(
;; 		i64.load(i32.sub(i32.add(input, len), 8)), 
;; 		i64.sub(
;; 			i64.xor(
;; 				i64.load(i32.add(secret, 40)),
;; 				i64.load(i32.add(secret, 48))
;; 			),
;; 			seed
;; 		)
;; 	)
;;  return XXH3_avalanche(
;;    i64.add(
;;      i64.extend_i32_u(len),
;;      i64.add(
;;        i64.add(XXH_swap64(input_lo), input_hi),
;;        XXH3_mul128_fold64(input_lo, input_hi)
;;      )
;;    )
;; )
(func $XXH3_len_9to16_64b (param $input i32) (param $len i32) (param $secret i32) (param $seed i64) (result i64)
  (local $input_lo i64)
  (local $input_hi i64)
  (local.set $input_lo 
    (i64.xor 
      (i64.load (local.get $input))
      (i64.add 
        (i64.xor
          (i64.load offset=24 (local.get $secret))
          (i64.load offset=32 (local.get $secret)))
        (local.get $seed))))
  (local.set $input_hi
    (i64.xor 
      (i64.load (i32.sub (i32.add (local.get $input) (local.get $len)) (i32.const 8)))
      (i64.sub 
        (i64.xor
          (i64.load offset=40 (local.get $secret))
          (i64.load offset=48 (local.get $secret)))
        (local.get $seed))))
  (call $XXH3_avalanche 
    (i64.add 
      (i64.extend_i32_u (local.get $len))
      (i64.add 
        (i64.add (call $XXH_swap64 (local.get $input_lo)) (local.get $input_hi))
        (call $XXH3_mul128_fold64 (local.get $input_lo) (local.get $input_hi))))))


;; XXH3_len_17to128_64b(input, len, secret, secretSize, seed):
;;     u64 acc = i64.add(i64.mul(len, XXH_PRIME64_1), XXH3_mix16B(input, secret, seed))
;;     u64 acc_end = XXH3_mix16B(
;;     	i32.sub(i32.add(input, len), 16),
;;     	i32.add(secret, 16),
;;     	seed
;;     )
;;     if (len > 32) {
;;         acc = i64.add(acc, XXH3_mix16B(i32.add(input, 16), i32.add(secret, 32), seed))
;;         acc_end = i64.add(acc_end, XXH3_mix16B(i32.sub(i32.add(input, len), 32), i32.add(secret, 48), seed))
;;         if (len > 64) {
;;             acc = i64.add(acc, XXH3_mix16B(i32.add(input, 32), i32.add(secret, 64), seed))
;;             acc_end = i64.add(acc_end, XXH3_mix16B(i32.sub(i32.add(input, len), 48), i32.add(secret, 80), seed))
;; 
;;             if (len > 96) {
;;                 acc = i64.add(acc, XXH3_mix16B(i32.add(input, 48), i32.add(secret, 96), seed))
;;                 acc_end = i64.add(acc_end, XXH3_mix16B(i32.sub(i32.add(input, len), 64), i32.add(secret, 112), seed))
;;             }
;;         }
;;     }
;;     return XXH3_avalanche(i64.add(acc, acc_end))
(func $XXH3_len_17to128_64b (param $input i32) (param $len i32) (param $secret i32) (param $secretSize i32) (param $seed i64) (result i64)
  (local $acc i64)
  (local $acc_end i64)
  (local.set $acc 
    (i64.add 
      (i64.mul (i64.extend_i32_u(local.get $len)) (global.get $PRIME64_1))
      (call $XXH3_mix16B (local.get $input) (local.get $secret) (local.get $seed))))
  (local.set $acc_end 
    (call $XXH3_mix16B 
      (i32.sub (i32.add (local.get $input) (local.get $len)) (i32.const 16)) 
      (i32.add (local.get $secret) (i32.const 16))
      (local.get $seed)))
  (if (i32.gt_u (local.get $len) (i32.const 32))
    (then
      (local.set $acc (i64.add (local.get $acc) (call $XXH3_mix16B (i32.add (local.get $input) (i32.const 16)) (i32.add (local.get $secret) (i32.const 32)) (local.get $seed))))
      (local.set $acc_end 
        (i64.add 
          (local.get $acc_end) 
            (call $XXH3_mix16B 
              (i32.sub (i32.add (local.get $input) (local.get $len)) (i32.const 32))
              (i32.add (local.get $secret) (i32.const 48))
              (local.get $seed))))
      (if (i32.gt_u (local.get $len) (i32.const 64))
        (then
          (local.set $acc (i64.add (local.get $acc) (call $XXH3_mix16B (i32.add (local.get $input) (i32.const 32)) (i32.add (local.get $secret) (i32.const 64)) (local.get $seed))))
          (local.set $acc_end 
            (i64.add 
              (local.get $acc_end) 
                (call $XXH3_mix16B 
                  (i32.sub (i32.add (local.get $input) (local.get $len)) (i32.const 48))
                  (i32.add (local.get $secret) (i32.const 80))
                  (local.get $seed))))
          (if (i32.gt_u (local.get $len) (i32.const 96))
          (then
            (local.set $acc (i64.add (local.get $acc) (call $XXH3_mix16B (i32.add (local.get $input) (i32.const 48)) (i32.add (local.get $secret) (i32.const 96)) (local.get $seed))))
            (local.set $acc_end 
              (i64.add 
                (local.get $acc_end) 
                  (call $XXH3_mix16B 
                    (i32.sub (i32.add (local.get $input) (local.get $len)) (i32.const 64))
                    (i32.add (local.get $secret) (i32.const 112))
                    (local.get $seed))))))))))
  (call $XXH3_avalanche (i64.add (local.get $acc) (local.get $acc_end))))


;; XXH3_len_129to240_64b(input, len, secret, secretSize, seed):
;;     xxh_u64 acc = i64.mul(i64.extend_i32_u(len), XXH_PRIME64_1)
;; 
;;     for (u32 i=0; i < 8; i++) {
;;         acc = i64.add(
;;         	acc,
;;         	XXH3_mix16B(
;;         		i32.add(input, i32.shl(i, 4)),
;;         		i32.add(secret, i32.shl(i, 4)),
;;         		seed
;;         	)
;;         )
;;     }
;; 
;;     u64 acc_end = XXH3_mix16B(
;;     	i32.sub(i32.add(input, len), 16),
;;     	i32.add(secret, 119),
;;     	seed
;;     )
;;     acc = XXH3_avalanche(acc)
;; 
;;     nbRounds = i32.shr_u(len, 4)
;;     for (u32 i = 8 ; i < nbRounds; i++) {
;;         acc_end = i32.add(
;;         	acc_end,
;;         	XXH3_mix16B(
;;         		i32.add(input, i32.shl(i, 4)),
;;         		i32.add(i32.add(secret, i32.shl(i32.sub(i, 8), 4)), 3),
;;         		seed
;;         	)
;;         )
;;     }
;;     return XXH3_avalanche(i64.add(acc, acc_end));
(func $XXH3_len_129to240_64b (param $input i32) (param $len i32) (param $secret i32) (param $secretSize i32) (param $seed i64) (result i64)
  (local $acc i64)
  (local $acc_end i64)
  (local $nbRounds i32)
  (local $i i32)
  (local.set $acc (i64.mul (i64.extend_i32_u (local.get $len)) (global.get $PRIME64_1)))
  (local.set $i (i32.const 0))
  (loop $l
    (local.set $acc (i64.add (local.get $acc)
      (call $XXH3_mix16B
        (i32.add (local.get $input) (i32.shl (local.get $i) (i32.const 4)))
        (i32.add (local.get $secret) (i32.shl (local.get $i) (i32.const 4)))
        (local.get $seed))))
    (local.set $i (i32.add (local.get $i) (i32.const 1)))
    (br_if $l (i32.lt_u (local.get $i) (i32.const 8))))
  (local.set $acc_end
    (call $XXH3_mix16B
      (i32.sub (i32.add (local.get $input) (local.get $len)) (i32.const 16))
      (i32.add (local.get $secret) (i32.const 119))
      (local.get $seed)))
  (local.set $acc (call $XXH3_avalanche (local.get $acc)))
  (local.set $nbRounds (i32.shr_u (local.get $len) (i32.const 4)))
  (local.set $i (i32.const 8))
  (block $exit
    (loop $l
      (br_if $exit (i32.ge_u (local.get $i) (local.get $nbRounds)))
      (local.set $acc_end 
        (i64.add 
          (local.get $acc_end)
          (call $XXH3_mix16B
            (i32.add (local.get $input) (i32.shl (local.get $i) (i32.const 4)))
            (i32.add 
              (i32.add 
                (local.get $secret)
                (i32.shl (i32.sub (local.get $i) (i32.const 8)) (i32.const 4)))
              (i32.const 3))
            (local.get $seed))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l)))
  (call $XXH3_avalanche (i64.add (local.get $acc) (local.get $acc_end))))


)



