C+
      SUBROUTINE GEN_IVSORT(PTRS,N,M,WORK,DATA)
C
C     G E N _ I V S O R T
C
C     Given a vector that gives the order of elements in an array
C     GEN_IVSORT reorders the contents of the array accordingly.
C     The vector will probably be generated by an indirect sorting
C     routine such as GEN_QFISORT. This is a version of GEN_FVSORT
C     for use with integer data.
C
C     Parameters -  (">" input, "W" workspace, "!" modified)
C
C     (>) PTRS    (Integer array PTRS(N)) The vector giving the
C                 order for the elements in DATA.  Ie the elements
C                 DATA(PTRS(1),i) are to be first in the reordered
C                 array, and DATA(PTRS(N),i) are to be last.
C     (>) N       (Integer) The first dimension of DATA.
C     (>) M       (Integer) The second dimension of DATA.
C     (W) WORK    (Integer array WORK(N)) Workspace.
C     (!) DATA    (Integer array DATA(N,M)) Data to be reordered.
C                 Returned in the order specified by PTRS.
C
C     Common variables used - None.
C
C     Subroutines / functions used -
C
C     GEN_MOVE    Fast move of bytes between arrays.
C                 (Note: The use of GEN_MOVE makes this code VAX-
C                 specific.)
C
C                                   KS / AAO 25th Nov 1985
C+
      IMPLICIT NONE
C
C     Parameters
C
      INTEGER M,N,PTRS(N),DATA(N,M),WORK(N)
C
C     Local variables
C
      INTEGER I,J
C
      DO J=1,M
         DO I=1,N
            WORK(I)=DATA(PTRS(I),J)
         END DO
         CALL GEN_MOVE(4*N,WORK,DATA(1,J))
      END DO
C
      END
