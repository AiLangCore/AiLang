#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/stdlib-behavior"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/number-null.aos" <<'AOS'
Program#stdlib_behavior_number_p1 {
  Import#stdlib_behavior_number_i1(path="../../src/std/number.aos")
  Import#stdlib_behavior_number_i2(path="../../src/std/null.aos")
  Import#stdlib_behavior_number_i3(path="../../src/std/io.aos")
  Import#stdlib_behavior_number_i4(path="../../src/std/core.aos")
  Import#stdlib_behavior_number_i5(path="../../src/std/bool.aos")
  Export#stdlib_behavior_number_e1(name=start)

  Let#stdlib_behavior_number_l1(name=start) {
    Fn#stdlib_behavior_number_f1(params=args) {
      Block#stdlib_behavior_number_b1 {
        Call#stdlib_behavior_number_c1(target=io.print) {
          Call#stdlib_behavior_number_c2(target=toString) {
            Call#stdlib_behavior_number_c3(target=negate) { Lit#stdlib_behavior_number_i1(value=7) }
          }
        }
        Call#stdlib_behavior_number_c4(target=io.print) {
          Call#stdlib_behavior_number_c5(target=toString) {
            Call#stdlib_behavior_number_c6(target=negate) { Lit#stdlib_behavior_number_i2(value=-7) }
          }
        }
        Call#stdlib_behavior_number_c7(target=io.print) {
          Call#stdlib_behavior_number_c8(target=toString) {
            Call#stdlib_behavior_number_c9(target=sub) { Lit#stdlib_behavior_number_i3(value=10) Lit#stdlib_behavior_number_i4(value=3) }
          }
        }
        Call#stdlib_behavior_number_c10(target=io.print) {
          Call#stdlib_behavior_number_c11(target=toString) {
            Call#stdlib_behavior_number_c12(target=sub) { Lit#stdlib_behavior_number_i5(value=3) Lit#stdlib_behavior_number_i6(value=10) }
          }
        }
        Call#stdlib_behavior_number_c13(target=io.print) {
          Call#stdlib_behavior_number_c14(target=toString) {
            Call#stdlib_behavior_number_c15(target=mul) { Lit#stdlib_behavior_number_i7(value=6) Lit#stdlib_behavior_number_i8(value=7) }
          }
        }
        Call#stdlib_behavior_number_c16(target=io.print) {
          Call#stdlib_behavior_number_c17(target=toString) {
            Call#stdlib_behavior_number_c18(target=mul) { Lit#stdlib_behavior_number_i9(value=6) Lit#stdlib_behavior_number_i10(value=-7) }
          }
        }
        Call#stdlib_behavior_number_c19(target=io.print) {
          ToString#stdlib_behavior_number_t1 {
            Call#stdlib_behavior_number_c20(target=isNumberString) { Lit#stdlib_behavior_number_i11(value="-42") }
          }
        }
        Call#stdlib_behavior_number_c21(target=io.print) {
          Call#stdlib_behavior_number_c22(target=toString) {
            Call#stdlib_behavior_number_c23(target=parseNumberOr) { Lit#stdlib_behavior_number_i12(value="-42") Lit#stdlib_behavior_number_i13(value=7) }
          }
        }
        Call#stdlib_behavior_number_c24(target=io.print) {
          Call#stdlib_behavior_number_c25(target=toString) {
            Call#stdlib_behavior_number_c26(target=parseNumberOr) { Lit#stdlib_behavior_number_i14(value="-") Lit#stdlib_behavior_number_i15(value=7) }
          }
        }
        Call#stdlib_behavior_number_c27(target=io.print) {
          Call#stdlib_behavior_number_c28(target=coalesce) {
            Call#stdlib_behavior_number_c29(target=value) { Lit#stdlib_behavior_number_i16(value=0) }
            Lit#stdlib_behavior_number_i17(value="fallback")
          }
        }
        Call#stdlib_behavior_number_c30(target=io.print) {
          Call#stdlib_behavior_number_c31(target=toString) {
            Call#stdlib_behavior_number_c32(target=div) { Lit#stdlib_behavior_number_i19(value=7) Lit#stdlib_behavior_number_i20(value=2) }
          }
        }
        Call#stdlib_behavior_number_c33(target=io.print) {
          Call#stdlib_behavior_number_c34(target=toString) {
            Call#stdlib_behavior_number_c35(target=mod) { Lit#stdlib_behavior_number_i21(value=7) Lit#stdlib_behavior_number_i22(value=2) }
          }
        }
        Call#stdlib_behavior_number_c36(target=io.print) {
          Call#stdlib_behavior_number_c37(target=toString) {
            Call#stdlib_behavior_number_c38(target=pow) { Lit#stdlib_behavior_number_i23(value=2) Lit#stdlib_behavior_number_i24(value=3) }
          }
        }
        Call#stdlib_behavior_number_c39(target=io.print) {
          Call#stdlib_behavior_number_c40(target=toString) {
            Call#stdlib_behavior_number_c41(target=compare) { Lit#stdlib_behavior_number_i25(value=1) Lit#stdlib_behavior_number_i26(value=2) }
          }
        }
        Call#stdlib_behavior_number_c42(target=io.print) {
          Call#stdlib_behavior_number_c43(target=toString) {
            Call#stdlib_behavior_number_c44(target=compare) { Lit#stdlib_behavior_number_i27(value=2) Lit#stdlib_behavior_number_i28(value=2) }
          }
        }
        Call#stdlib_behavior_number_c45(target=io.print) {
          Call#stdlib_behavior_number_c46(target=toString) {
            Call#stdlib_behavior_number_c47(target=compare) { Lit#stdlib_behavior_number_i29(value=3) Lit#stdlib_behavior_number_i30(value=2) }
          }
        }
        Call#stdlib_behavior_number_c48(target=io.print) {
          ToString#stdlib_behavior_number_t2 {
            Call#stdlib_behavior_number_c49(target=betweenInclusive) { Lit#stdlib_behavior_number_i31(value=2) Lit#stdlib_behavior_number_i32(value=1) Lit#stdlib_behavior_number_i33(value=3) }
          }
        }
        Call#stdlib_behavior_number_c50(target=io.print) {
          ToString#stdlib_behavior_number_t3 {
            Call#stdlib_behavior_number_c51(target=betweenExclusive) { Lit#stdlib_behavior_number_i34(value=2) Lit#stdlib_behavior_number_i35(value=1) Lit#stdlib_behavior_number_i36(value=3) }
          }
        }
        Call#stdlib_behavior_number_c52(target=io.print) {
          Call#stdlib_behavior_number_c53(target=toString) {
            Call#stdlib_behavior_number_c54(target=div) { Lit#stdlib_behavior_number_i37(value=6) Lit#stdlib_behavior_number_i38(value=3) }
          }
        }
        Call#stdlib_behavior_number_c55(target=io.print) {
          Call#stdlib_behavior_number_c56(target=toString) {
            Call#stdlib_behavior_number_c57(target=pow) { Lit#stdlib_behavior_number_i39(value=5) Lit#stdlib_behavior_number_i40(value=0) }
          }
        }
        Call#stdlib_behavior_number_c58(target=io.print) {
          Call#stdlib_behavior_number_c59(target=toString) {
            Call#stdlib_behavior_number_c60(target=pow) { Lit#stdlib_behavior_number_i41(value=2) Lit#stdlib_behavior_number_i42(value=1) }
          }
        }
        Call#stdlib_behavior_number_c61(target=io.print) { ToString#stdlib_behavior_number_t4 { Call#stdlib_behavior_number_c62(target=lt) { Lit#stdlib_behavior_number_i43(value=1) Lit#stdlib_behavior_number_i44(value=2) } } }
        Call#stdlib_behavior_number_c63(target=io.print) { ToString#stdlib_behavior_number_t5 { Call#stdlib_behavior_number_c64(target=lt) { Lit#stdlib_behavior_number_i45(value=2) Lit#stdlib_behavior_number_i46(value=1) } } }
        Call#stdlib_behavior_number_c65(target=io.print) { ToString#stdlib_behavior_number_t6 { Call#stdlib_behavior_number_c66(target=lte) { Lit#stdlib_behavior_number_i47(value=2) Lit#stdlib_behavior_number_i48(value=2) } } }
        Call#stdlib_behavior_number_c67(target=io.print) { ToString#stdlib_behavior_number_t7 { Call#stdlib_behavior_number_c68(target=lte) { Lit#stdlib_behavior_number_i49(value=1) Lit#stdlib_behavior_number_i50(value=2) } } }
        Call#stdlib_behavior_number_c69(target=io.print) { ToString#stdlib_behavior_number_t8 { Call#stdlib_behavior_number_c70(target=gt) { Lit#stdlib_behavior_number_i51(value=3) Lit#stdlib_behavior_number_i52(value=2) } } }
        Call#stdlib_behavior_number_c71(target=io.print) { ToString#stdlib_behavior_number_t9 { Call#stdlib_behavior_number_c72(target=gt) { Lit#stdlib_behavior_number_i53(value=2) Lit#stdlib_behavior_number_i54(value=3) } } }
        Call#stdlib_behavior_number_c73(target=io.print) { ToString#stdlib_behavior_number_t10 { Call#stdlib_behavior_number_c74(target=gte) { Lit#stdlib_behavior_number_i55(value=2) Lit#stdlib_behavior_number_i56(value=2) } } }
        Call#stdlib_behavior_number_c75(target=io.print) { ToString#stdlib_behavior_number_t11 { Call#stdlib_behavior_number_c76(target=gte) { Lit#stdlib_behavior_number_i57(value=3) Lit#stdlib_behavior_number_i58(value=2) } } }
        Call#stdlib_behavior_number_c77(target=io.print) { ToString#stdlib_behavior_number_t12 { Call#stdlib_behavior_number_c78(target=betweenInclusive) { Lit#stdlib_behavior_number_i59(value=1) Lit#stdlib_behavior_number_i60(value=1) Lit#stdlib_behavior_number_i61(value=3) } } }
        Call#stdlib_behavior_number_c79(target=io.print) { ToString#stdlib_behavior_number_t13 { Call#stdlib_behavior_number_c80(target=betweenInclusive) { Lit#stdlib_behavior_number_i62(value=3) Lit#stdlib_behavior_number_i63(value=1) Lit#stdlib_behavior_number_i64(value=3) } } }
        Call#stdlib_behavior_number_c81(target=io.print) { ToString#stdlib_behavior_number_t14 { Call#stdlib_behavior_number_c82(target=betweenExclusive) { Lit#stdlib_behavior_number_i65(value=1) Lit#stdlib_behavior_number_i66(value=1) Lit#stdlib_behavior_number_i67(value=3) } } }
        Call#stdlib_behavior_number_c83(target=io.print) { ToString#stdlib_behavior_number_t15 { Call#stdlib_behavior_number_c84(target=betweenExclusive) { Lit#stdlib_behavior_number_i68(value=3) Lit#stdlib_behavior_number_i69(value=1) Lit#stdlib_behavior_number_i70(value=3) } } }
        Call#stdlib_behavior_number_c85(target=io.print) { ToString#stdlib_behavior_number_t16 { Call#stdlib_behavior_number_c86(target=not) { Call#stdlib_behavior_number_c87(target=equals) { Lit#stdlib_behavior_number_i71(value=2) Lit#stdlib_behavior_number_i72(value=2) } } } }
        Call#stdlib_behavior_number_c88(target=io.print) { ToString#stdlib_behavior_number_t17 { Call#stdlib_behavior_number_c89(target=not) { Call#stdlib_behavior_number_c90(target=equals) { Lit#stdlib_behavior_number_i73(value=2) Lit#stdlib_behavior_number_i74(value=3) } } } }
        Call#stdlib_behavior_number_c91(target=io.print) { ToString#stdlib_behavior_number_t18 { Call#stdlib_behavior_number_c92(target=xor) { Call#stdlib_behavior_number_c93(target=lt) { Lit#stdlib_behavior_number_i75(value=1) Lit#stdlib_behavior_number_i76(value=2) } Call#stdlib_behavior_number_c94(target=gt) { Lit#stdlib_behavior_number_i77(value=1) Lit#stdlib_behavior_number_i78(value=2) } } } }
        Call#stdlib_behavior_number_c95(target=io.print) { Call#stdlib_behavior_number_c96(target=toString) { Call#stdlib_behavior_number_c97(target=add) { Lit#stdlib_behavior_number_i79(value=1.5) Lit#stdlib_behavior_number_i80(value=2) } } }
        Call#stdlib_behavior_number_c98(target=io.print) { Call#stdlib_behavior_number_c99(target=toString) { Call#stdlib_behavior_number_c100(target=sub) { Lit#stdlib_behavior_number_i81(value=5.5) Lit#stdlib_behavior_number_i82(value=2) } } }
        Call#stdlib_behavior_number_c101(target=io.print) { Call#stdlib_behavior_number_c102(target=toString) { Call#stdlib_behavior_number_c103(target=mul) { Lit#stdlib_behavior_number_i83(value=1.5) Lit#stdlib_behavior_number_i84(value=2) } } }
        Call#stdlib_behavior_number_c104(target=io.print) { Call#stdlib_behavior_number_c105(target=toString) { Call#stdlib_behavior_number_c106(target=mod) { Lit#stdlib_behavior_number_i85(value=7.5) Lit#stdlib_behavior_number_i86(value=2) } } }
        Call#stdlib_behavior_number_c107(target=io.print) { ToString#stdlib_behavior_number_t19 { Call#stdlib_behavior_number_c108(target=lt) { Lit#stdlib_behavior_number_i87(value=1.5) Lit#stdlib_behavior_number_i88(value=2) } } }
        Call#stdlib_behavior_number_c109(target=io.print) { ToString#stdlib_behavior_number_t20 { Call#stdlib_behavior_number_c110(target=equals) { Lit#stdlib_behavior_number_i89(value=2) Lit#stdlib_behavior_number_i90(value=2.0) } } }
        Return#stdlib_behavior_number_r1 { Lit#stdlib_behavior_number_i18(value=0) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/math.aos" <<'AOS'
Program#stdlib_behavior_math_p1 {
  Import#stdlib_behavior_math_i1(path="../../src/std/math.aos")
  Import#stdlib_behavior_math_i2(path="../../src/std/io.aos")
  Export#stdlib_behavior_math_e1(name=start)

  Let#stdlib_behavior_math_l1(name=start) {
    Fn#stdlib_behavior_math_f1(params=args) {
      Block#stdlib_behavior_math_b1 {
        Call#stdlib_behavior_math_c1(target=io.print) {
          ToString#stdlib_behavior_math_t1 {
            Call#stdlib_behavior_math_c2(target=halfFloor) { Lit#stdlib_behavior_math_i1(value=9) Lit#stdlib_behavior_math_i2(value=0) }
          }
        }
        Call#stdlib_behavior_math_c3(target=io.print) {
          ToString#stdlib_behavior_math_t2 {
            Call#stdlib_behavior_math_c4(target=divFloor) { Lit#stdlib_behavior_math_i3(value=10) Lit#stdlib_behavior_math_i4(value=3) Lit#stdlib_behavior_math_i4a(value=0) }
          }
        }
        Call#stdlib_behavior_math_c5(target=io.print) {
          ToString#stdlib_behavior_math_t3 {
            Call#stdlib_behavior_math_c6(target=subAbs) { Lit#stdlib_behavior_math_i5(value=3) Lit#stdlib_behavior_math_i6(value=10) }
          }
        }
        Return#stdlib_behavior_math_r1 { Lit#stdlib_behavior_math_i19(value=0) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/bool.aos" <<'AOS'
Program#stdlib_behavior_bool_p1 {
  Import#stdlib_behavior_bool_i1(path="../../src/std/bool.aos")
  Import#stdlib_behavior_bool_i2(path="../../src/std/io.aos")
  Export#stdlib_behavior_bool_e1(name=start)

  Let#stdlib_behavior_bool_l1(name=start) {
    Fn#stdlib_behavior_bool_f1(params=args) {
      Block#stdlib_behavior_bool_b1 {
        Call#stdlib_behavior_bool_c1(target=io.print) { ToString#stdlib_behavior_bool_t1 { Call#stdlib_behavior_bool_c2(target=not) { Lit#stdlib_behavior_bool_i1(value=true) } } }
        Call#stdlib_behavior_bool_c3(target=io.print) { ToString#stdlib_behavior_bool_t2 { Call#stdlib_behavior_bool_c4(target=not) { Lit#stdlib_behavior_bool_i2(value=false) } } }
        Call#stdlib_behavior_bool_c5(target=io.print) { ToString#stdlib_behavior_bool_t3 { Call#stdlib_behavior_bool_c6(target=and) { Lit#stdlib_behavior_bool_i3(value=true) Lit#stdlib_behavior_bool_i4(value=true) } } }
        Call#stdlib_behavior_bool_c7(target=io.print) { ToString#stdlib_behavior_bool_t4 { Call#stdlib_behavior_bool_c8(target=and) { Lit#stdlib_behavior_bool_i5(value=true) Lit#stdlib_behavior_bool_i6(value=false) } } }
        Call#stdlib_behavior_bool_c9(target=io.print) { ToString#stdlib_behavior_bool_t5 { Call#stdlib_behavior_bool_c10(target=and) { Lit#stdlib_behavior_bool_i7(value=false) Lit#stdlib_behavior_bool_i8(value=true) } } }
        Call#stdlib_behavior_bool_c11(target=io.print) { ToString#stdlib_behavior_bool_t6 { Call#stdlib_behavior_bool_c12(target=and) { Lit#stdlib_behavior_bool_i9(value=false) Lit#stdlib_behavior_bool_i10(value=false) } } }
        Call#stdlib_behavior_bool_c13(target=io.print) { ToString#stdlib_behavior_bool_t7 { Call#stdlib_behavior_bool_c14(target=or) { Lit#stdlib_behavior_bool_i11(value=true) Lit#stdlib_behavior_bool_i12(value=true) } } }
        Call#stdlib_behavior_bool_c15(target=io.print) { ToString#stdlib_behavior_bool_t8 { Call#stdlib_behavior_bool_c16(target=or) { Lit#stdlib_behavior_bool_i13(value=true) Lit#stdlib_behavior_bool_i14(value=false) } } }
        Call#stdlib_behavior_bool_c17(target=io.print) { ToString#stdlib_behavior_bool_t9 { Call#stdlib_behavior_bool_c18(target=or) { Lit#stdlib_behavior_bool_i15(value=false) Lit#stdlib_behavior_bool_i16(value=true) } } }
        Call#stdlib_behavior_bool_c19(target=io.print) { ToString#stdlib_behavior_bool_t10 { Call#stdlib_behavior_bool_c20(target=or) { Lit#stdlib_behavior_bool_i17(value=false) Lit#stdlib_behavior_bool_i18(value=false) } } }
        Call#stdlib_behavior_bool_c21(target=io.print) { ToString#stdlib_behavior_bool_t11 { Call#stdlib_behavior_bool_c22(target=xor) { Lit#stdlib_behavior_bool_i19(value=true) Lit#stdlib_behavior_bool_i20(value=true) } } }
        Call#stdlib_behavior_bool_c23(target=io.print) { ToString#stdlib_behavior_bool_t12 { Call#stdlib_behavior_bool_c24(target=xor) { Lit#stdlib_behavior_bool_i21(value=true) Lit#stdlib_behavior_bool_i22(value=false) } } }
        Call#stdlib_behavior_bool_c25(target=io.print) { ToString#stdlib_behavior_bool_t13 { Call#stdlib_behavior_bool_c26(target=xor) { Lit#stdlib_behavior_bool_i23(value=false) Lit#stdlib_behavior_bool_i24(value=true) } } }
        Call#stdlib_behavior_bool_c27(target=io.print) { ToString#stdlib_behavior_bool_t14 { Call#stdlib_behavior_bool_c28(target=xor) { Lit#stdlib_behavior_bool_i25(value=false) Lit#stdlib_behavior_bool_i26(value=false) } } }
        Return#stdlib_behavior_bool_r1 { Lit#stdlib_behavior_bool_i13(value=0) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/core-str.aos" <<'AOS'
Program#stdlib_behavior_core_str_p1 {
  Import#stdlib_behavior_core_str_i1(path="../../src/std/core.aos")
  Import#stdlib_behavior_core_str_i2(path="../../src/std/str.aos")
  Import#stdlib_behavior_core_str_i3(path="../../src/std/io.aos")
  Export#stdlib_behavior_core_str_e1(name=start)

  Let#stdlib_behavior_core_str_l1(name=start) {
    Fn#stdlib_behavior_core_str_f1(params=args) {
      Block#stdlib_behavior_core_str_b1 {
        Let#stdlib_behavior_core_str_l2(name=ok) {
          Call#stdlib_behavior_core_str_c1(target=resultOkString) {
            Lit#stdlib_behavior_core_str_i1(value="value")
          }
        }
        Let#stdlib_behavior_core_str_l3(name=err) {
          Call#stdlib_behavior_core_str_c2(target=resultErr) {
            Lit#stdlib_behavior_core_str_i2(value="E_TEST")
            Lit#stdlib_behavior_core_str_i3(value="failed")
          }
        }
        Let#stdlib_behavior_core_str_l4(name=some) {
          Call#stdlib_behavior_core_str_c3(target=optionSomeString) {
            Lit#stdlib_behavior_core_str_i4(value="present")
          }
        }
        Let#stdlib_behavior_core_str_l5(name=none) {
          Call#stdlib_behavior_core_str_c4(target=optionNone) {
            Lit#stdlib_behavior_core_str_i5(value=0)
          }
        }
        Call#stdlib_behavior_core_str_c8(target=io.print) {
          ToString#stdlib_behavior_core_str_t1 {
            Call#stdlib_behavior_core_str_c9(target=resultIsOk) {
              Var#stdlib_behavior_core_str_v3(name=ok)
            }
          }
        }
        Call#stdlib_behavior_core_str_c10(target=io.print) {
          Call#stdlib_behavior_core_str_c11(target=resultValueOr) {
            Var#stdlib_behavior_core_str_v4(name=ok)
            Lit#stdlib_behavior_core_str_i8(value="fallback")
          }
        }
        Call#stdlib_behavior_core_str_c12(target=io.print) {
          Call#stdlib_behavior_core_str_c13(target=resultCodeOr) {
            Var#stdlib_behavior_core_str_v5(name=err)
            Lit#stdlib_behavior_core_str_i9(value="NO_CODE")
          }
        }
        Call#stdlib_behavior_core_str_c14(target=io.print) {
          Call#stdlib_behavior_core_str_c15(target=resultMessageOr) {
            Var#stdlib_behavior_core_str_v6(name=err)
            Lit#stdlib_behavior_core_str_i10(value="NO_MESSAGE")
          }
        }
        Call#stdlib_behavior_core_str_c16(target=io.print) {
          ToString#stdlib_behavior_core_str_t2 {
            Call#stdlib_behavior_core_str_c17(target=optionHas) {
              Var#stdlib_behavior_core_str_v7(name=some)
            }
          }
        }
        Call#stdlib_behavior_core_str_c18(target=io.print) {
          Call#stdlib_behavior_core_str_c19(target=optionValueOr) {
            Var#stdlib_behavior_core_str_v8(name=none)
            Lit#stdlib_behavior_core_str_i11(value="empty")
          }
        }
        Call#stdlib_behavior_core_str_c20(target=io.print) {
          Call#stdlib_behavior_core_str_c21(target=concat) {
            Lit#stdlib_behavior_core_str_i12(value="ai")
            Lit#stdlib_behavior_core_str_i13(value="lang")
          }
        }
        Call#stdlib_behavior_core_str_c22(target=io.print) {
          Call#stdlib_behavior_core_str_c23(target=substring) {
            Lit#stdlib_behavior_core_str_i14(value="abcdef")
            Lit#stdlib_behavior_core_str_i15(value=2)
            Lit#stdlib_behavior_core_str_i16(value=3)
          }
        }
        Call#stdlib_behavior_core_str_c24(target=io.print) {
          Call#stdlib_behavior_core_str_c25(target=remove) {
            Lit#stdlib_behavior_core_str_i17(value="abcdef")
            Lit#stdlib_behavior_core_str_i18(value=2)
            Lit#stdlib_behavior_core_str_i19(value=2)
          }
        }
        Call#stdlib_behavior_core_str_c26(target=io.print) {
          ToString#stdlib_behavior_core_str_t3 {
            Call#stdlib_behavior_core_str_c27(target=find) {
              Lit#stdlib_behavior_core_str_i20(value="abcabc")
              Lit#stdlib_behavior_core_str_i21(value="ca")
              Lit#stdlib_behavior_core_str_i22(value=0)
            }
          }
        }
        Call#stdlib_behavior_core_str_c28(target=io.print) {
          Call#stdlib_behavior_core_str_c29(target=replaceAll) {
            Lit#stdlib_behavior_core_str_i23(value="one fish one fish")
            Lit#stdlib_behavior_core_str_i24(value="fish")
            Lit#stdlib_behavior_core_str_i25(value="cat")
          }
        }
        Call#stdlib_behavior_core_str_c30(target=io.print) {
          Call#stdlib_behavior_core_str_c31(target=fromCodePoint) {
            Lit#stdlib_behavior_core_str_i26(value=65)
          }
        }
        Call#stdlib_behavior_core_str_c32(target=io.print) {
          ToString#stdlib_behavior_core_str_t4 {
            Call#stdlib_behavior_core_str_c33(target=equals) { Lit#stdlib_behavior_core_str_i27(value=1) Lit#stdlib_behavior_core_str_i28(value=1) }
          }
        }
        Call#stdlib_behavior_core_str_c34(target=io.print) {
          ToString#stdlib_behavior_core_str_t5 {
            Call#stdlib_behavior_core_str_c35(target=equals) { Lit#stdlib_behavior_core_str_i29(value=1) Lit#stdlib_behavior_core_str_i30(value=2) }
          }
        }
        Call#stdlib_behavior_core_str_c36(target=io.print) {
          ToString#stdlib_behavior_core_str_t6 {
            Call#stdlib_behavior_core_str_c37(target=equals) { Lit#stdlib_behavior_core_str_i32(value="a") Lit#stdlib_behavior_core_str_i33(value="a") }
          }
        }
        Call#stdlib_behavior_core_str_c38(target=io.print) {
          ToString#stdlib_behavior_core_str_t7 {
            Call#stdlib_behavior_core_str_c39(target=equals) { Lit#stdlib_behavior_core_str_i34(value="a") Lit#stdlib_behavior_core_str_i35(value="b") }
          }
        }
        Call#stdlib_behavior_core_str_c40(target=io.print) {
          ToString#stdlib_behavior_core_str_t8 {
            Call#stdlib_behavior_core_str_c41(target=equals) { Lit#stdlib_behavior_core_str_i36(value=true) Lit#stdlib_behavior_core_str_i37(value=true) }
          }
        }
        Call#stdlib_behavior_core_str_c42(target=io.print) {
          ToString#stdlib_behavior_core_str_t9 {
            Call#stdlib_behavior_core_str_c43(target=equals) { Lit#stdlib_behavior_core_str_i38(value=true) Lit#stdlib_behavior_core_str_i39(value=false) }
          }
        }
        Call#stdlib_behavior_core_str_c44(target=io.print) {
          ToString#stdlib_behavior_core_str_t10 {
            Call#stdlib_behavior_core_str_c45(target=equals) { Lit#stdlib_behavior_core_str_i40(value=null) Lit#stdlib_behavior_core_str_i41(value=null) }
          }
        }
        Call#stdlib_behavior_core_str_c46(target=io.print) {
          ToString#stdlib_behavior_core_str_t11 {
            Call#stdlib_behavior_core_str_c47(target=equals) { Lit#stdlib_behavior_core_str_i42(value="string") Lit#stdlib_behavior_core_str_i43(value=null) }
          }
        }
        Call#stdlib_behavior_core_str_c48(target=io.print) {
          ToString#stdlib_behavior_core_str_t12 {
            Call#stdlib_behavior_core_str_c49(target=equals) { Lit#stdlib_behavior_core_str_i44(value=1) Lit#stdlib_behavior_core_str_i45(value="1") }
          }
        }
        Call#stdlib_behavior_core_str_c50(target=io.print) {
          ToString#stdlib_behavior_core_str_t13 {
            Call#stdlib_behavior_core_str_c51(target=length) { Lit#stdlib_behavior_core_str_i46(value="abc") }
          }
        }
        Call#stdlib_behavior_core_str_c52(target=io.print) {
          ToString#stdlib_behavior_core_str_t14 {
            Call#stdlib_behavior_core_str_c53(target=str.len) { Lit#stdlib_behavior_core_str_i47(value="éx") }
          }
        }
        Return#stdlib_behavior_core_str_r1 { Lit#stdlib_behavior_core_str_i31(value=0) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/bytes.aos" <<'AOS'
Program#stdlib_behavior_bytes_p1 {
  Import#stdlib_behavior_bytes_i1(path="../../src/std/bytes.aos")
  Import#stdlib_behavior_bytes_i2(path="../../src/std/io.aos")
  Export#stdlib_behavior_bytes_e1(name=start)

  Let#stdlib_behavior_bytes_l1(name=start) {
    Fn#stdlib_behavior_bytes_f1(params=args) {
      Block#stdlib_behavior_bytes_b1 {
        Let#stdlib_behavior_bytes_l2(name=data) {
          Call#stdlib_behavior_bytes_c1(target=bytes.fromUtf8String) {
            Lit#stdlib_behavior_bytes_i1(value="hello")
          }
        }
        Let#stdlib_behavior_bytes_l3(name=tail) {
          Call#stdlib_behavior_bytes_c2(target=bytes.fromUtf8String) {
            Lit#stdlib_behavior_bytes_i2(value="!")
          }
        }
        Let#stdlib_behavior_bytes_l4(name=joinedBytes) {
          Call#stdlib_behavior_bytes_c3(target=bytes.concat) {
            Var#stdlib_behavior_bytes_v1(name=data)
            Var#stdlib_behavior_bytes_v2(name=tail)
          }
        }
        Call#stdlib_behavior_bytes_c4(target=io.print) {
          ToString#stdlib_behavior_bytes_t1 {
            Call#stdlib_behavior_bytes_c5(target=bytes.length) {
              Var#stdlib_behavior_bytes_v3(name=data)
            }
          }
        }
        Call#stdlib_behavior_bytes_c6(target=io.print) {
          ToString#stdlib_behavior_bytes_t2 {
            Call#stdlib_behavior_bytes_c7(target=bytes.at) {
              Var#stdlib_behavior_bytes_v4(name=data)
              Lit#stdlib_behavior_bytes_i3(value=1)
            }
          }
        }
        Call#stdlib_behavior_bytes_c8(target=io.print) {
          Call#stdlib_behavior_bytes_c9(target=bytes.toUtf8String) {
            Call#stdlib_behavior_bytes_c10(target=bytes.slice) {
              Var#stdlib_behavior_bytes_v5(name=joinedBytes)
              Lit#stdlib_behavior_bytes_i4(value=1)
              Lit#stdlib_behavior_bytes_i5(value=4)
            }
          }
        }
        Call#stdlib_behavior_bytes_c11(target=io.print) {
          Call#stdlib_behavior_bytes_c12(target=bytes.toBase64) {
            Var#stdlib_behavior_bytes_v6(name=data)
          }
        }
        Call#stdlib_behavior_bytes_c13(target=io.print) {
          Call#stdlib_behavior_bytes_c14(target=bytes.toUtf8String) {
            Call#stdlib_behavior_bytes_c15(target=bytes.fromBase64) {
              Lit#stdlib_behavior_bytes_i6(value="aGVsbG8=")
            }
          }
        }
        Call#stdlib_behavior_bytes_c16(target=io.print) {
          Call#stdlib_behavior_bytes_c17(target=bytes.toBase64) {
            Call#stdlib_behavior_bytes_c18(target=bytes.fromByte) {
              Lit#stdlib_behavior_bytes_i8(value=65)
            }
          }
        }
        Call#stdlib_behavior_bytes_c19(target=io.print) {
          Call#stdlib_behavior_bytes_c20(target=bytes.toBase64) {
            Call#stdlib_behavior_bytes_c21(target=bytes.u32le) {
              Lit#stdlib_behavior_bytes_i9(value=305419896)
            }
          }
        }
        Call#stdlib_behavior_bytes_c22(target=io.print) {
          Call#stdlib_behavior_bytes_c23(target=bytes.toBase64) {
            Call#stdlib_behavior_bytes_c24(target=bytes.i64le) {
              Lit#stdlib_behavior_bytes_i10(value=1)
            }
          }
        }
        Return#stdlib_behavior_bytes_r1 { Lit#stdlib_behavior_bytes_i7(value=0) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/io-debug.aos" <<'AOS'
Program#stdlib_behavior_io_debug_p1 {
  Import#stdlib_behavior_io_debug_i1(path="../../src/std/io.aos")
  Import#stdlib_behavior_io_debug_i2(path="../../src/std/debug.aos")
  Export#stdlib_behavior_io_debug_e1(name=start)

  Let#stdlib_behavior_io_debug_l1(name=start) {
    Fn#stdlib_behavior_io_debug_f1(params=args) {
      Block#stdlib_behavior_io_debug_b1 {
        Call#stdlib_behavior_io_debug_c1(target=write) {
          Lit#stdlib_behavior_io_debug_i1(value="out-a")
        }
        Call#stdlib_behavior_io_debug_c2(target=writeLine) {
          Lit#stdlib_behavior_io_debug_i2(value="out-b")
        }
        Call#stdlib_behavior_io_debug_c3(target=writeErrLine) {
          Lit#stdlib_behavior_io_debug_i3(value="err-a")
        }
        Call#stdlib_behavior_io_debug_c4(target=info) {
          Lit#stdlib_behavior_io_debug_i4(value="hello")
        }
        Call#stdlib_behavior_io_debug_c5(target=warn) {
          Lit#stdlib_behavior_io_debug_i5(value="careful")
        }
        Call#stdlib_behavior_io_debug_c6(target=error) {
          Lit#stdlib_behavior_io_debug_i6(value="bad")
        }
        Call#stdlib_behavior_io_debug_c7(target=log) {
          Lit#stdlib_behavior_io_debug_i7(value="audit")
          Lit#stdlib_behavior_io_debug_i8(value="trail")
        }
        Call#stdlib_behavior_io_debug_c8(target=debugAssert) {
          Lit#stdlib_behavior_io_debug_i9(value=true)
          Lit#stdlib_behavior_io_debug_i10(value="ASSERT_OK")
          Lit#stdlib_behavior_io_debug_i11(value="assertion passed")
        }
        Return#stdlib_behavior_io_debug_r1 { Lit#stdlib_behavior_io_debug_i12(value=0) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/fs.aos" <<AOS
Program#stdlib_behavior_fs_p1 {
  Import#stdlib_behavior_fs_i1(path="../../src/std/fs.aos")
  Import#stdlib_behavior_fs_i2(path="../../src/std/bytes.aos")
  Import#stdlib_behavior_fs_i3(path="../../src/std/io.aos")
  Export#stdlib_behavior_fs_e1(name=start)

  Let#stdlib_behavior_fs_l1(name=start) {
    Fn#stdlib_behavior_fs_f1(params=args) {
      Block#stdlib_behavior_fs_b1 {
        Let#stdlib_behavior_fs_l2(name=filePath) {
          Lit#stdlib_behavior_fs_s1(value="${TMP_DIR}/fs-behavior.txt")
        }
        Let#stdlib_behavior_fs_l3(name=dirPath) {
          Lit#stdlib_behavior_fs_s2(value="${TMP_DIR}/fs-behavior-dir")
        }
        Call#stdlib_behavior_fs_c1(target=fileWrite) {
          Var#stdlib_behavior_fs_v1(name=filePath)
          Call#stdlib_behavior_fs_c2(target=bytes.fromUtf8String) {
            Lit#stdlib_behavior_fs_s3(value="fs-ok")
          }
        }
        Call#stdlib_behavior_fs_c3(target=io.print) {
          ToString#stdlib_behavior_fs_t1 {
            Call#stdlib_behavior_fs_c4(target=fileExists) {
              Var#stdlib_behavior_fs_v2(name=filePath)
            }
          }
        }
        Call#stdlib_behavior_fs_c5(target=io.print) {
          ToString#stdlib_behavior_fs_t2 {
            Call#stdlib_behavior_fs_c6(target=pathExists) {
              Var#stdlib_behavior_fs_v3(name=filePath)
            }
          }
        }
        Call#stdlib_behavior_fs_c7(target=io.print) {
          Call#stdlib_behavior_fs_c8(target=bytes.toUtf8String) {
            Call#stdlib_behavior_fs_c9(target=fileRead) {
              Var#stdlib_behavior_fs_v4(name=filePath)
            }
          }
        }
        Call#stdlib_behavior_fs_c10(target=fileDelete) {
          Var#stdlib_behavior_fs_v5(name=filePath)
        }
        Call#stdlib_behavior_fs_c11(target=io.print) {
          ToString#stdlib_behavior_fs_t3 {
            Call#stdlib_behavior_fs_c12(target=fileExists) {
              Var#stdlib_behavior_fs_v6(name=filePath)
            }
          }
        }
        Call#stdlib_behavior_fs_c13(target=dirCreate) {
          Var#stdlib_behavior_fs_v7(name=dirPath)
        }
        Call#stdlib_behavior_fs_c14(target=io.print) {
          ToString#stdlib_behavior_fs_t4 {
            Call#stdlib_behavior_fs_c15(target=pathExists) {
              Var#stdlib_behavior_fs_v8(name=dirPath)
            }
          }
        }
        Call#stdlib_behavior_fs_c16(target=dirDelete) {
          Var#stdlib_behavior_fs_v9(name=dirPath)
          Lit#stdlib_behavior_fs_b2(value=true)
        }
        Call#stdlib_behavior_fs_c17(target=io.print) {
          ToString#stdlib_behavior_fs_t5 {
            Call#stdlib_behavior_fs_c18(target=pathExists) {
              Var#stdlib_behavior_fs_v10(name=dirPath)
            }
          }
        }
        Return#stdlib_behavior_fs_r1 { Lit#stdlib_behavior_fs_i1(value=0) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/process-system.aos" <<'AOS'
Program#stdlib_behavior_process_system_p1 {
  Import#stdlib_behavior_process_system_i1(path="../../src/std/process.aos")
  Import#stdlib_behavior_process_system_i2(path="../../src/std/system.aos")
  Import#stdlib_behavior_process_system_i3(path="../../src/std/io.aos")
  Export#stdlib_behavior_process_system_e1(name=start)

  Let#stdlib_behavior_process_system_l1(name=start) {
    Fn#stdlib_behavior_process_system_f1(params=args) {
      Block#stdlib_behavior_process_system_b1 {
        Call#stdlib_behavior_process_system_c1(target=io.print) {
          Call#stdlib_behavior_process_system_c2(target=cwd) {
            Lit#stdlib_behavior_process_system_i1(value=0)
          }
        }
        Call#stdlib_behavior_process_system_c3(target=io.print) {
          Call#stdlib_behavior_process_system_c4(target=envGet) {
            Lit#stdlib_behavior_process_system_s1(value="AILANG_STDLIB_BEHAVIOR_ENV")
          }
        }
        Call#stdlib_behavior_process_system_c5(target=io.print) {
          Call#stdlib_behavior_process_system_c6(target=platform) {
            Lit#stdlib_behavior_process_system_i2(value=0)
          }
        }
        Call#stdlib_behavior_process_system_c7(target=io.print) {
          Call#stdlib_behavior_process_system_c8(target=arch) {
            Lit#stdlib_behavior_process_system_i3(value=0)
          }
        }
        Call#stdlib_behavior_process_system_c9(target=io.print) {
          Call#stdlib_behavior_process_system_c10(target=runtime) {
            Lit#stdlib_behavior_process_system_i4(value=0)
          }
        }
        Return#stdlib_behavior_process_system_r1 {
          Lit#stdlib_behavior_process_system_i5(value=0)
        }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/time.aos" <<'AOS'
Program#stdlib_behavior_time_p1 {
  Import#stdlib_behavior_time_i1(path="../../src/std/time.aos")
  Import#stdlib_behavior_time_i2(path="../../src/std/io.aos")
  Import#stdlib_behavior_time_i3(path="../../src/std/date_time.aos")
  Export#stdlib_behavior_time_e1(name=start)

  Let#stdlib_behavior_time_l1(name=start) {
    Fn#stdlib_behavior_time_f1(params=args) {
      Block#stdlib_behavior_time_b1 {
        Let#stdlib_behavior_time_l2(name=utc) {
          Call#stdlib_behavior_time_c1(target=timeUtc) {
            Lit#stdlib_behavior_time_i1(value=12345)
          }
        }
        Call#stdlib_behavior_time_c2(target=io.print) {
          ToString#stdlib_behavior_time_t1 {
            Call#stdlib_behavior_time_c3(target=timeUnixMs) {
              Var#stdlib_behavior_time_v1(name=utc)
            }
          }
        }
        Call#stdlib_behavior_time_c4(target=io.print) {
          Call#stdlib_behavior_time_c5(target=timeZone) {
            Var#stdlib_behavior_time_v2(name=utc)
          }
        }
        Call#stdlib_behavior_time_c6(target=io.print) {
          ToString#stdlib_behavior_time_t2 {
            Call#stdlib_behavior_time_c7(target=timeOffsetMinutes) {
              Var#stdlib_behavior_time_v3(name=utc)
            }
          }
        }
        Call#stdlib_behavior_time_c8(target=io.print) {
          ToString#stdlib_behavior_time_t3 {
            Call#stdlib_behavior_time_c9(target=timeIsUtc) {
              Var#stdlib_behavior_time_v4(name=utc)
            }
          }
        }
        Call#stdlib_behavior_time_c10(target=io.print) {
          ToString#stdlib_behavior_time_t4 {
            Call#stdlib_behavior_time_c11(target=localDayIndexFromUnixMs) {
              Lit#stdlib_behavior_time_i3(value=0)
              Lit#stdlib_behavior_time_i4(value=0)
            }
          }
        }
        Call#stdlib_behavior_time_c12(target=io.print) {
          Call#stdlib_behavior_time_c13(target=relativeDayLabelFromBaseDayIndex) {
            Lit#stdlib_behavior_time_i5(value=0)
            Lit#stdlib_behavior_time_i6(value=1)
          }
        }
        Call#stdlib_behavior_time_c14(target=io.print) {
          Call#stdlib_behavior_time_c15(target=relativeDayLabelFromBaseDayIndex) {
            Lit#stdlib_behavior_time_i7(value=0)
            Lit#stdlib_behavior_time_i8(value=3)
          }
        }
        Call#stdlib_behavior_time_c16(target=io.print) {
          Call#stdlib_behavior_time_c17(target=relativeDayLabelFromBaseDayIndex) {
            Lit#stdlib_behavior_time_i9(value=20623)
            Lit#stdlib_behavior_time_i10(value=0)
          }
        }
        Call#stdlib_behavior_time_c18(target=io.print) {
          Call#stdlib_behavior_time_c19(target=relativeDayLabelFromBaseDayIndex) {
            Lit#stdlib_behavior_time_i11(value=20623)
            Lit#stdlib_behavior_time_i12(value=1)
          }
        }
        Call#stdlib_behavior_time_c20(target=io.print) {
          Call#stdlib_behavior_time_c21(target=relativeDayLabelFromBaseDayIndex) {
            Lit#stdlib_behavior_time_i13(value=20623)
            Lit#stdlib_behavior_time_i14(value=2)
          }
        }
        Call#stdlib_behavior_time_c22(target=io.print) {
          Call#stdlib_behavior_time_c23(target=relativeDayLabelFromBaseDayIndex) {
            Lit#stdlib_behavior_time_i15(value=20623)
            Lit#stdlib_behavior_time_i16(value=3)
          }
        }
        Call#stdlib_behavior_time_c24(target=io.print) {
          Call#stdlib_behavior_time_c25(target=relativeDayLabelFromBaseDayIndex) {
            Lit#stdlib_behavior_time_i17(value=20623)
            Lit#stdlib_behavior_time_i18(value=4)
          }
        }
        Call#stdlib_behavior_time_c26(target=io.print) {
          ToString#stdlib_behavior_time_t5 {
            Call#stdlib_behavior_time_c27(target=dayIndexFromIsoDate) {
              Lit#stdlib_behavior_time_s5(value="2026-06-19")
            }
          }
        }
        Call#stdlib_behavior_time_c28(target=io.print) {
          Call#stdlib_behavior_time_c29(target=relativeDayLabelFromIsoDate) {
            Lit#stdlib_behavior_time_i21(value="2026-06-19")
            Lit#stdlib_behavior_time_i22(value="2026-06-20")
          }
        }
        Call#stdlib_behavior_time_c30(target=io.print) {
          Call#stdlib_behavior_time_c31(target=relativeDayLabelFromIsoDate) {
            Lit#stdlib_behavior_time_i23(value="2026-06-19")
            Lit#stdlib_behavior_time_i24(value="2026-06-21")
          }
        }
        Call#stdlib_behavior_time_c32(target=io.print) {
          Call#stdlib_behavior_time_c33(target=relativeDayLabelFromIsoDate) {
            Lit#stdlib_behavior_time_i25(value="2026-06-19")
            Lit#stdlib_behavior_time_i26(value="2026-06-22")
          }
        }
        Call#stdlib_behavior_time_c34(target=io.print) {
          Call#stdlib_behavior_time_c35(target=relativeDayLabelFromIsoDate) {
            Lit#stdlib_behavior_time_i27(value="2026-06-19")
            Lit#stdlib_behavior_time_i28(value="2026-06-23")
          }
        }
        Return#stdlib_behavior_time_r1 { Lit#stdlib_behavior_time_i2(value=0) }
      }
    }
  }
}
AOS

NUMBER_NULL_OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/number-null.aos")"
NUMBER_NULL_EXPECTED='-7
7
7
-7
42
-42
true
-42
7
fallback
3.5
1
8
-1
0
1
true
true
2
1
2
true
false
true
true
true
false
true
true
true
true
false
false
false
true
true
3.5
3.5
3
1.5
true
true
Ok#ok1(type=int value=0)'

if [[ "${NUMBER_NULL_OUT}" != "${NUMBER_NULL_EXPECTED}" ]]; then
  echo "stdlib number/null behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${NUMBER_NULL_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${NUMBER_NULL_OUT}" >&2
  exit 1
fi

MATH_OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/math.aos")"
MATH_EXPECTED='4
3
7
Ok#ok1(type=int value=0)'

if [[ "${MATH_OUT}" != "${MATH_EXPECTED}" ]]; then
  echo "stdlib math behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${MATH_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${MATH_OUT}" >&2
  exit 1
fi

BOOL_OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/bool.aos")"
BOOL_EXPECTED='false
true
true
false
false
false
true
true
true
false
false
true
true
false
Ok#ok1(type=int value=0)'

if [[ "${BOOL_OUT}" != "${BOOL_EXPECTED}" ]]; then
  echo "stdlib bool behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${BOOL_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${BOOL_OUT}" >&2
  exit 1
fi

CORE_STR_OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/core-str.aos")"
CORE_STR_EXPECTED='true
value
E_TEST
failed
true
empty
ailang
cde
abef
2
one cat one cat
A
true
false
true
false
true
false
true
false
false
3
2
Ok#ok1(type=int value=0)'

if [[ "${CORE_STR_OUT}" != "${CORE_STR_EXPECTED}" ]]; then
  echo "stdlib core/str behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${CORE_STR_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${CORE_STR_OUT}" >&2
  exit 1
fi

BYTES_OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/bytes.aos")"
BYTES_EXPECTED='5
101
ello
aGVsbG8=
hello
QQ==
eFY0Eg==
AQAAAAAAAAA=
Ok#ok1(type=int value=0)'

if [[ "${BYTES_OUT}" != "${BYTES_EXPECTED}" ]]; then
  echo "stdlib bytes behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${BYTES_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${BYTES_OUT}" >&2
  exit 1
fi

IO_DEBUG_STDOUT="${TMP_DIR}/io-debug.stdout"
IO_DEBUG_STDERR="${TMP_DIR}/io-debug.stderr"
"${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/io-debug.aos" >"${IO_DEBUG_STDOUT}" 2>"${IO_DEBUG_STDERR}"

IO_DEBUG_STDOUT_EXPECTED='out-aout-b
Ok#ok1(type=int value=0)'
IO_DEBUG_STDERR_EXPECTED='err-a
[info] hello
[warn] careful
[error] bad
[audit] trail'

IO_DEBUG_STDOUT_ACTUAL="$(cat "${IO_DEBUG_STDOUT}")"
IO_DEBUG_STDERR_ACTUAL="$(cat "${IO_DEBUG_STDERR}")"

if [[ "${IO_DEBUG_STDOUT_ACTUAL}" != "${IO_DEBUG_STDOUT_EXPECTED}" ]]; then
  echo "stdlib io/debug stdout behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${IO_DEBUG_STDOUT_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${IO_DEBUG_STDOUT_ACTUAL}" >&2
  exit 1
fi

if [[ "${IO_DEBUG_STDERR_ACTUAL}" != "${IO_DEBUG_STDERR_EXPECTED}" ]]; then
  echo "stdlib io/debug stderr behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${IO_DEBUG_STDERR_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${IO_DEBUG_STDERR_ACTUAL}" >&2
  exit 1
fi

FS_OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/fs.aos")"
FS_EXPECTED='true
true
fs-ok
false
true
false
Ok#ok1(type=int value=0)'

if [[ "${FS_OUT}" != "${FS_EXPECTED}" ]]; then
  echo "stdlib fs behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${FS_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${FS_OUT}" >&2
  exit 1
fi

PROCESS_SYSTEM_OUT="$(
  AILANG_STDLIB_BEHAVIOR_ENV=stdlib-ok \
    "${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/process-system.aos"
)"
PROCESS_SYSTEM_EXPECTED_PREFIX="${ROOT_DIR}
stdlib-ok"

if [[ "${PROCESS_SYSTEM_OUT}" != "${PROCESS_SYSTEM_EXPECTED_PREFIX}"$'\n'* ]]; then
  echo "stdlib process/system cwd/env behavior mismatch" >&2
  echo "expected prefix:" >&2
  printf '%s\n' "${PROCESS_SYSTEM_EXPECTED_PREFIX}" >&2
  echo "actual:" >&2
  printf '%s\n' "${PROCESS_SYSTEM_OUT}" >&2
  exit 1
fi

PROCESS_SYSTEM_LINE_COUNT="$(printf '%s\n' "${PROCESS_SYSTEM_OUT}" | wc -l | tr -d ' ')"
if [[ "${PROCESS_SYSTEM_LINE_COUNT}" != "6" ]]; then
  echo "stdlib process/system line count mismatch" >&2
  printf '%s\n' "${PROCESS_SYSTEM_OUT}" >&2
  exit 1
fi

TIME_OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/time.aos")"
TIME_EXPECTED='12345
UTC
0
true
0
Tomorrow
Sunday
Today
Tomorrow
Sunday
Monday
Tuesday
20623
Tomorrow
Sunday
Monday
Tuesday
Ok#ok1(type=int value=0)'

if [[ "${TIME_OUT}" != "${TIME_EXPECTED}" ]]; then
  echo "stdlib time behavior mismatch" >&2
  echo "expected:" >&2
  printf '%s\n' "${TIME_EXPECTED}" >&2
  echo "actual:" >&2
  printf '%s\n' "${TIME_OUT}" >&2
  exit 1
fi

echo "stdlib behavior: PASS"
