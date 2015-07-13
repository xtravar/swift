// RUN: %target-swift-frontend -disable-func-sig-opts -O -emit-sil -primary-file %s | FileCheck %s
// RUN: %target-swift-frontend -disable-func-sig-opts -O -wmo -emit-sil -primary-file %s | FileCheck -check-prefix=CHECK-WMO %s

// Check that values of internal and private global variables, which are provably assigned only 
// once, are propagated into their uses and enable further optimizations like constant
// propagation, simplifications, etc.

// Define some global variables.

public var VD = 3.1415
public var VI = 100

private var PVD = 3.1415
private var PVI = 100
private var PVIAssignTwice = 1
private var PVITakenAddress = 1


internal var IVD = 3.1415
internal var IVI = 100
internal var IVIAssignTwice = 1
internal var IVITakenAddress = 1

// Taking the address of a global should prevent from performing the propagation of its value.
@inline(never)
public func takeInout<T>(inout x:T) {
}

// Compiler should detect that we assign a global here as well and prevent a global optimization.
public func assignSecondTime() {
  PVIAssignTwice = 2
  IVIAssignTwice = 2
}

// Having multiple assignments to a global should prevent from performing the propagation of its value.

// Loads from private global variables can be removed, 
// because they cannot be changed outside of this source file.
// CHECK-LABEL: sil [noinline] @_TF28globalopt_global_propagation30test_private_global_var_doubleFT_Sd
// CHECK: bb0:
// CHECK-NOT: global_addr
// CHECK: float_literal
// CHECK: struct
// CHECK: return
@inline(never)
public func test_private_global_var_double() -> Double {
  return PVD + 1.0 
}

// Loads from private global variables can be removed, 
// because they cannot be changed outside of this source file.
// CHECK-LABEL: sil [noinline] @_TF28globalopt_global_propagation27test_private_global_var_intFT_Si
// CHECK: bb0:
// CHECK-NOT: global_addr
// CHECK: integer_literal
// CHECK: struct
// CHECK: return
@inline(never)
public func test_private_global_var_int() -> Int {
  return PVI + 1
}

// Loads from internal global variables can be removed if this is a WMO compilation, because
// they cannot be changed outside of this module.
// CHECK-WMO-LABEL: sil [noinline] @_TF28globalopt_global_propagation31test_internal_global_var_doubleFT_Sd
// CHECK-WMO: bb0:
// CHECK-WMO-NOT: global_addr
// CHECK-WMO: float_literal
// CHECK-WMO: struct
// CHECK-WMO: return
@inline(never)
public func test_internal_global_var_double() -> Double {
  return IVD + 1.0 
}

// Loads from internal global variables can be removed if this is a WMO compilation, because
// they cannot be changed outside of this module.
// CHECK-WMO-LABEL: sil [noinline] @_TF28globalopt_global_propagation28test_internal_global_var_intFT_Si
// CHECK_WMO: bb0:
// CHECK-WMO-NOT: global_addr
// CHECK-WMO: integer_literal
// CHECK-WMO: struct
// CHECK_WMO: return
@inline(never)
public func test_internal_global_var_int() -> Int {
  return IVI + 1
}

// Loads from public global variables cannot be removed, because their values could be changed elsewhere.
// CHECK-WMO-LABEL: sil [noinline] @_TF28globalopt_global_propagation29test_public_global_var_doubleFT_Sd
// CHECK-WMO: bb0:
// CHECK-WMO-NEXT: global_addr
// CHECK-WMO-NEXT: struct_element_addr
// CHECK-WMO-NEXT: load
@inline(never)
public func test_public_global_var_double() -> Double {
  return VD + 1.0 
}


// Loads from public global variables cannot be removed, because their values could be changed elsewhere.
// CHECK-LABEL: sil [noinline] @_TF28globalopt_global_propagation26test_public_global_var_intFT_Si
// CHECK: bb0: 
// CHECK-NEXT: global_addr
// CHECK-NEXT: struct_element_addr
// CHECK-NEXT: load
@inline(never)
public func test_public_global_var_int() -> Int {
  return VI + 1
}

// Values of globals cannot be propagated as there are multiple assignments to it.
// CHECK-WMO-LABEL: sil [noinline] @_TF28globalopt_global_propagation57test_internal_and_private_global_var_with_two_assignmentsFT_Si
// CHECK-WMO: bb0: 
// CHECK-WMO: global_addr
// CHECK-WMO: global_addr
// CHECK-WMO: struct_element_addr
// CHECK-WMO: load
// CHECK-WMO: struct_element_addr
// CHECK-WMO: load
// CHECK-WMO: return
@inline(never)
public func test_internal_and_private_global_var_with_two_assignments() -> Int {
  return IVIAssignTwice + PVIAssignTwice
}

// Values of globals cannot be propagated as their address was taken and
// therefore their value could have been changed elsewhere.
// CHECK-WMO-LABEL: sil @_TF28globalopt_global_propagation24test_global_take_addressFT_Si
// CHECK-WMO: bb0:
// CHECK-WMO: global_addr
// CHECK-WMO: global_addr
// CHECK-WMO: struct_element_addr
// CHECK-WMO: load
// CHECK-WMO: struct_element_addr
// CHECK-WMO: load
// CHECK-WMO: return
public func test_global_take_address() -> Int {
  takeInout(&PVITakenAddress)
  takeInout(&IVITakenAddress)
  return IVITakenAddress + PVITakenAddress
}