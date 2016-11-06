#lang racket

;estou estruturando o pit é uma STRUCTURE com dois FIELDS. Snake é o primeiro field, e o segundo filed, GOO, fala o numero de bixinhos
;o pit é um FOSSO

(struct pit (snake goos) #:transparent)

; a estrutura da cobra também tem dois FIELDS, a direção e a LISTA de segmentos, segs
;segs nunca vai ser vazio, a cobra sempre tem pelo menos uma unidade de comprimento

(struct snake (dir segs) #:transparent)

; posn é um ponto no espaço de duas dimensões

(struct posn (x y) #:transparent)

;pensa que cada corpo é um objeto no espaço, ocorre colisão quando dois objetos tem a mesma posição, ou seja, a mesma posn

;loc é a posição do GOO
;expire representa o tempo que o GOO ainda vai existir, depois disso ele desaparece

(struct goo (loc expire) #:transparent)

;defini uma snake de exemplo usando a estrutura, no primeiro campo, tem up, no segundo tem o tamanho da cobra
(define snake-example
  (snake "up" (list (posn 1 1) (posn 1 2) (posn 1 3))))

;defini um exemplo de goo, na real, criei DOIS GOOS, um na posicação (1,0) e outro na posição (5,8),
; cada um feito para sobreviver um tempo também

(define goo-example
  (list (goo (posn 1 1) 3) (goo (posn 5 8) 15)))

(define goo-example-two
  (list (goo (posn 9 9) 3) (goo (posn 5 8) 15)))

(define goo-example-three
  (list (goo (posn 5 8) 3) (goo (posn 1 1) 15)))


;esse pit coloca as duas coisas definidas acima juntas
(define pit-example
  (pit snake-example goo-example))

;olha aí, como eu acesso os fields de um objeto, primeiro pegando um GOO e depois pegando a ABCISSA da localização desse GOO!

#|USA O TESTES PARA MOSTRAR COMO CHAMA CARALHO!!!!|#


;to usando pit aqui dentro da sua estrutura, primeiro a cobra, e, no outro field, varios GOOS juntos

;CONSTRUINDO O JOGO MESMO
;

(require 2htdp/universe 2htdp/image)

(define (start-snake)
  (big-bang (pit (snake "right" (list (posn 1 1))) ;snake começa na direção da direita, na posição (1,1) e com uma unidade de cumprimento, a cabeça
                 (random-num-goos))
            (on-tick next-pit TICK-RATE) ;aqui tem uma criação temporal, faz a cobra CRESCER e se MOVER. Além de fazer desaparecer GOO
            (on-key direct-snake) ;on-key do big bang chama o direct snake
            (to-draw render-pit) ;to-draw chama o RENDER-pit
            (stop-when dead? render-end))) ; o stop-when dead? chama o render-end

; w é o TICK RATE
(define (next-pit w) ; essa função controla o tempo, faz o GOO envelhecer, e a cobra ENGORDAR se ela come
  (define snake (pit-snake w)) ;pit-snake nada mais é que a SNAKE no PIT
  (define goos (pit-goos w))
  (define goo-to-eat (can-eat snake goos)) ;veja que goo to eat é definido INTERNAMENTE
  (if goo-to-eat
      (pit (grow snake) (age-goo (eat goos goo-to-eat))); se GOO to eat for verdadeiro, chama pit (grow snake)
      (pit (slither snake) (age-goo goos)))); se não for verdadeiro, chama o pit com (slither snake)

; age-goo faz os GOOS envelhecerem!

;olha só que bacana, essa função é recursiva

(define (can-eat snake goos)
  (cond [(empty? goos) #f] ;se a lista de goos for vazia, a cobra não consegue comer
        [else (if (close? (snake-head snake) (first goos)) ;close checa se a cabeça da cobra está perto de um GOO
                  (first goos)
                  (can-eat snake (rest goos)))]))
;definindo close

(define (close? s g)
  (posn=? s (goo-loc g)))

(define (eat goos goo-to-eat)
  (cons (fresh-goo) (remove goo-to-eat goos)))

(define (grow sn)
  (snake (snake-dir sn)
         (cons (next-head sn) (snake-segs sn))))

(define (slither sn)
  (snake (snake-dir sn)
         (cons (next-head sn) (all-but-last (snake-segs sn)))))

(define (all-but-last segs)
  (cond [(empty? (rest segs)) empty]
        [else (cons (first segs) (all-but-last (rest segs)))]))

(define (next-head sn)
  (define head (snake-head sn))
  (define dir (snake-dir sn))
  (cond [(string=? dir "up") (posn-move head 0 -1)]
        [(string=? dir "down") (posn-move head 0 1)]
        [(string=? dir "left") (posn-move head -1 0)]
        [(string=? dir "right") (posn-move head 1 0)]))

(define (posn-move p dx dy)
  (posn (+ (posn-x p) dx)
        (+ (posn-y p) dy)))

;definição de age-goo cá embaixo
;o que rot faz? não é built-in
(define (age-goo goos)
  (rot (renew goos)))

(define (rot goos)
  (cond [(empty? goos) empty]
        [else (cons (decay (first goos)) (rot (rest goos)))]))

(define (renew goos)
  (cond [(empty? goos) empty]
        [(rotten? (first goos))
         (cons (fresh-goo) (renew (rest goos)))]
        [else
         (cons (first goos) (renew (rest goos)))]))

(define (rotten? g)
  (zero? (goo-expire g)))

(define (fresh-goo)
  (goo (posn (add1 (random (sub1 SIZE)))
             (add1 (random (sub1 SIZE))))
       EXPIRATION-TIME))


(define (direct-snake w ke)
  (cond [(dir? ke) (world-change-dir w ke)]
        [else w]))

(define (dir? x)
  (or (key=? x "up")
      (key=? x "down")
      (key=? x "left")
      (key=? x "right")))

(define (world-change-dir w d)
  (define the-snake (pit-snake w))
  (cond [(and (opposite-dir? (snake-dir the-snake) d)
              ;; consists of the head and at least one segment
              (cons? (rest (snake-segs the-snake))))
         (stop-with w)]
        [else
         (pit (snake-change-dir the-snake d) (pit-goos w))]))

(define (opposite-dir? d1 d2)
  (cond [(string=? d1 "up") (string=? d2 "down")]
        [(string=? d1 "down") (string=? d2 "up")]
        [(string=? d1 "left") (string=? d2 "right")]
        [(string=? d1 "right") (string=? d2 "left")]))

;relacionada ao to-draw do BIG BANG
(define (render-pit w)
  (snake+scene (pit-snake w)
               (goo-list+scene (pit-goos w) MT-SCENE)))

(define (snake+scene snake scene)
  (define snake-body-scene
    (img-list+scene (snake-body snake) SEG-IMG scene))
  (define dir (snake-dir snake))
  (img+scene (snake-head snake)
             (cond [(string=? "up" dir) HEAD-UP-IMG]
                   [(string=? "down" dir) HEAD-DOWN-IMG]
                   [(string=? "left" dir) HEAD-LEFT-IMG]
                   [(string=? "right" dir) HEAD-RIGHT-IMG])
             snake-body-scene))

(define (img-list+scene posns img scene)
  (cond [(empty? posns) scene]
        [else (img+scene
               (first posns)
               img
               (img-list+scene (rest posns) img scene))]))

(define (img+scene posn img scene)
  (place-image img
               (* (posn-x posn) SEG-SIZE)
               (* (posn-y posn) SEG-SIZE)
               scene))

(define (goo-list+scene goos scene)
  (define (get-posns-from-goo goos)
    (cond [(empty? goos) empty]
          [else (cons (goo-loc (first goos))
                      (get-posns-from-goo (rest goos)))]))
  (img-list+scene (get-posns-from-goo goos) GOO-IMG scene))

(define (dead? w)
  (define snake (pit-snake w))
  (or (self-colliding? snake) (wall-colliding? snake)))

(define (render-end w)
  (overlay (text "Game Over" ENDGAME-TEXT-SIZE "black")))

#|(define (render-end w)
  (overlay (text "Game over" ENDGAME-TEXT-SIZE "black")
(render-pit w)))|#

(define (self-colliding? snake)
  (cons? (member (snake-head snake) (snake-body snake))))

(define (wall-colliding? snake)
  (define x (posn-x (snake-head snake)))
  (define y (posn-y (snake-head snake)))
  (or (= 0 x) (= x SIZE)
      (= 0 y) (= y SIZE)))

(define (posn=? p1 p2)
  (and (= (posn-x p1) (posn-x p2))
       (= (posn-y p1) (posn-y p2))))

(define (snake-head sn)
  (first (snake-segs sn)))

(define (snake-body sn)
  (rest (snake-segs sn)))

(define (snake-tail sn)
  (last (snake-segs sn)))

(define (snake-change-dir sn d)
  (snake d (snake-segs sn)))

(define (decay g)
  (goo (goo-loc g) (sub1 (goo-expire g))))

;; Constants

;; Tick Rate 
(define TICK-RATE 1/10)

;; Board Size Constants
(define SIZE 30)

;; Snake Constants
(define SEG-SIZE 15)

;; Goo Constants
(define MAX-GOO 5)
(define EXPIRATION-TIME 150)

;; GRAPHICAL BOARD
(define WIDTH-PX  (* SEG-SIZE 30))
(define HEIGHT-PX (* SEG-SIZE 30))

;; Visual constants
(define MT-SCENE (empty-scene WIDTH-PX HEIGHT-PX))
(define GOO-IMG (bitmap "goo.gif"))
(define SEG-IMG  (bitmap "body.gif"))
(define HEAD-IMG (bitmap "head.gif"))

(define HEAD-LEFT-IMG HEAD-IMG)
(define HEAD-DOWN-IMG (rotate 90 HEAD-LEFT-IMG))
(define HEAD-RIGHT-IMG (flip-horizontal HEAD-LEFT-IMG))
(define HEAD-UP-IMG (flip-vertical HEAD-DOWN-IMG))

(define ENDGAME-TEXT-SIZE 15)

(require racket/trace)

(length (snake-segs snake-example))

(define (random-num-goos)
  (define num (random 5 15))
  (define (random-num-goos-iter num accu)
    (if (= num 0)
        accu
        (random-num-goos-iter (- num 1) (cons (fresh-goo) accu ))))
  (trace random-num-goos-iter)
  (random-num-goos-iter num '()))

(start-snake)

;;;;;;;;;;;;;;;TESTES PARA CHECAR COMPREENSÃO DO CÓDIGO

(require rackunit)

(check-equal? (snake-segs snake-example) (list (posn 1 1) (posn 1 2) (posn 1 3)))
(check-equal? (snake-dir snake-example) "up")
(check-equal? (goo-expire (first goo-example)) 3)
(check-equal? (pit-snake pit-example) snake-example)
(check-equal? (pit-goos pit-example) goo-example)
(check-equal? (posn-x (posn 1 2)) 1)
(check-equal? (posn-y (posn 1 2)) 2)
(check-equal? (can-eat snake-example '()) #f)
(check-equal? (can-eat snake-example goo-example) (first goo-example))
(check-equal? (can-eat snake-example goo-example-two) #f)
(check-equal? (can-eat snake-example goo-example-three) (second goo-example-three))