#lang racket

(define (guess lower-boundary upper-boundary)
  (round (/ (+ lower-boundary upper-boundary) 2)))

(require racket/trace)

(define (game-iter number)
  (define (iter number count lower-boundary  upper-boundary accu)
    (cond ((= (guess lower-boundary upper-boundary) number) (values count (guess lower-boundary upper-boundary)))
          ((> (guess lower-boundary upper-boundary) number)
           (iter  number
                  (add1 count)
                  lower-boundary
                  (sub1 (guess lower-boundary upper-boundary))
                  (guess lower-boundary upper-boundary)))
          (else (iter number (add1 count) (add1 (guess lower-boundary upper-boundary)) upper-boundary (guess lower-boundary upper-boundary)))))
  (trace iter)
  (iter number 0 1 100 (guess 1 100)))

(game-iter 10)