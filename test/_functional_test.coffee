xobjective 'ensure it works on actual directory tree', ->

    #
    # requires test.tree/  .build
    #

    trace.filter = true

    beforeEach (Expander) ->

        @In = opts: $$caller: FileName: __filename
        @files = true
        @dirs = true

        @run = (mask) => Expander.perform @In, mask, @files, @dirs


    it 'finds the elephant and only the elephant',

        (done) ->

            @timeout 6000

            @run '../test.tree/*/e/*/ele*h*t'

            .then (r) ->

                done r.should.eql [
                    '../test.tree/words/e/ele/elephant'
                ]

            .catch done
                


    it 'finds all words ending in i',

        (done) ->

            @timeout 6000

            @run '../test.tree/**/*i'

            .then (r) ->

                # grep -e i$ test.tree/.words  | wc -l
                # 177 - i  (not *i)


                r.length.should.equal 176

                done r.should.eql [
                    '../test.tree/words/a/aba/abaci',
                    '../test.tree/words/a/ali/alibi',
                    '../test.tree/words/a/alk/alkali',
                    '../test.tree/words/a/alu/alumni',
                    '../test.tree/words/a/ant/anti',
                    '../test.tree/words/a/ant/antipasti',
                    '../test.tree/words/b/bac/bacilli',
                    '../test.tree/words/b/ban/banzai',
                    '../test.tree/words/b/ber/beriberi',
                    '../test.tree/words/b/bi/bi',
                    '../test.tree/words/b/bik/bikini',
                    '../test.tree/words/b/bli/blini',
                    '../test.tree/words/b/bon/bonsai',
                    '../test.tree/words/b/bor/borzoi',
                    '../test.tree/words/b/bou/bouzouki',
                    '../test.tree/words/b/bro/broccoli',
                    '../test.tree/words/b/bro/bronchi',
                    '../test.tree/words/c/cac/cacti',
                    '../test.tree/words/c/cad/caducei',
                    '../test.tree/words/c/cal/calamari',
                    '../test.tree/words/c/cal/calculi',
                    '../test.tree/words/c/can/cannelloni',
                    '../test.tree/words/c/car/caravanserai',
                    '../test.tree/words/c/car/carpi',
                    '../test.tree/words/c/chi/chi',
                    '../test.tree/words/c/chi/chichi',
                    '../test.tree/words/c/chi/chili',
                    '../test.tree/words/c/cir/cirri',
                    '../test.tree/words/c/coc/cocci',
                    '../test.tree/words/c/cog/cognoscenti',
                    '../test.tree/words/c/col/colossi',
                    '../test.tree/words/c/con/concerti',
                    '../test.tree/words/c/con/confetti',
                    '../test.tree/words/c/cor/corgi',
                    '../test.tree/words/c/cum/cumuli',
                    '../test.tree/words/d/dai/daiquiri',
                    '../test.tree/words/d/das/dashiki',
                    '../test.tree/words/d/del/deli',
                    '../test.tree/words/d/dho/dhoti',
                    '../test.tree/words/d/dig/digerati',
                    '../test.tree/words/d/dil/dilettanti',
                    '../test.tree/words/e/eff/effendi',
                    '../test.tree/words/e/enn/ennui',
                    '../test.tree/words/e/eso/esophagi',
                    '../test.tree/words/e/euc/eucalypti',
                    '../test.tree/words/f/foc/foci',
                    '../test.tree/words/f/fun/fungi',
                    '../test.tree/words/g/gen/genii',
                    '../test.tree/words/g/gla/gladioli',
                    '../test.tree/words/g/gli/glissandi',
                    '../test.tree/words/g/gra/graffiti',
                    '../test.tree/words/h/haj/hajji',
                    '../test.tree/words/h/har/hara-kiri',
                    '../test.tree/words/h/hi/hi',
                    '../test.tree/words/h/hi-/hi-fi',
                    '../test.tree/words/h/hib/hibachi',
                    '../test.tree/words/h/hip/hippopotami',
                    '../test.tree/words/h/hou/houri',
                    '../test.tree/words/h/hum/humeri',
                    '../test.tree/words/h/hyp/hypothalami',
                    '../test.tree/words/i/inc/incubi',
                    '../test.tree/words/j/jin/jinni',
                    '../test.tree/words/k/kab/kabuki',
                    '../test.tree/words/k/kep/kepi',
                    '../test.tree/words/k/kha/khaki',
                    '../test.tree/words/k/kie/kielbasi',
                    '../test.tree/words/k/kiw/kiwi',
                    '../test.tree/words/k/koh/kohlrabi',
                    '../test.tree/words/l/lan/lanai',
                    '../test.tree/words/l/lei/lei',
                    '../test.tree/words/l/lib/libretti',
                    '../test.tree/words/l/lin/linguini',
                    '../test.tree/words/l/lit/litchi',
                    '../test.tree/words/l/lit/literati',
                    '../test.tree/words/l/loc/loci',
                    '../test.tree/words/m/mac/macaroni',
                    '../test.tree/words/m/mae/maestri',
                    '../test.tree/words/m/maf/mafiosi',
                    '../test.tree/words/m/mag/magi',
                    '../test.tree/words/m/mah/maharani',
                    '../test.tree/words/m/mah/maharishi',
                    '../test.tree/words/m/mar/mariachi',
                    '../test.tree/words/m/mar/martini',
                    '../test.tree/words/m/max/maxi',
                    '../test.tree/words/m/men/menisci',
                    '../test.tree/words/m/met/metacarpi',
                    '../test.tree/words/m/met/metatarsi',
                    '../test.tree/words/m/mi/mi',
                    '../test.tree/words/m/mid/midi',
                    '../test.tree/words/m/min/mini',
                    '../test.tree/words/m/mon/monsignori',
                    '../test.tree/words/m/muf/mufti',
                    '../test.tree/words/n/nar/narcissi',
                    '../test.tree/words/n/nau/nautili',
                    '../test.tree/words/n/nev/nevi',
                    '../test.tree/words/n/nim/nimbi',
                    '../test.tree/words/n/nis/nisei',
                    '../test.tree/words/n/nuc/nuclei',
                    '../test.tree/words/n/nuc/nucleoli',
                    '../test.tree/words/o/obi/obi',
                    '../test.tree/words/o/oct/octopi',
                    '../test.tree/words/o/ori/origami',
                    '../test.tree/words/p/pap/paparazzi',
                    '../test.tree/words/p/pap/papyri',
                    '../test.tree/words/p/pas/pastrami',
                    '../test.tree/words/p/pep/pepperoni',
                    '../test.tree/words/p/pha/phalli',
                    '../test.tree/words/p/phi/phi',
                    '../test.tree/words/p/pi/pi',
                    '../test.tree/words/p/pic/piccalilli',
                    '../test.tree/words/p/pir/pirogi',
                    '../test.tree/words/p/pir/piroshki',
                    '../test.tree/words/p/poi/poi',
                    '../test.tree/words/p/pot/potpourri',
                    '../test.tree/words/p/psi/psi',
                    '../test.tree/words/p/pyl/pylori',
                    '../test.tree/words/q/qua/quasi',
                    '../test.tree/words/r/rab/rabbi',
                    '../test.tree/words/r/rad/radii',
                    '../test.tree/words/r/ran/rani',
                    '../test.tree/words/r/rav/ravioli',
                    '../test.tree/words/r/rho/rhombi',
                    '../test.tree/words/s/saf/safari',
                    '../test.tree/words/s/sal/salami',
                    '../test.tree/words/s/sam/samurai',
                    '../test.tree/words/s/sar/sarcophagi',
                    '../test.tree/words/s/sar/sari',
                    '../test.tree/words/s/sat/satori',
                    '../test.tree/words/s/sca/scampi',
                    '../test.tree/words/s/sch/scherzi',
                    '../test.tree/words/s/sci/sci-fi',
                    '../test.tree/words/s/sem/semi',
                    '../test.tree/words/s/sha/shanghai',
                    '../test.tree/words/s/sig/signori',
                    '../test.tree/words/s/ski/ski',
                    '../test.tree/words/s/spa/spaghetti',
                    '../test.tree/words/s/spu/spumoni',
                    '../test.tree/words/s/sta/staphylococci',
                    '../test.tree/words/s/sti/stimuli',
                    '../test.tree/words/s/str/strati',
                    '../test.tree/words/s/str/streptococci',
                    '../test.tree/words/s/sty/styli',
                    '../test.tree/words/s/suk/sukiyaki',
                    '../test.tree/words/s/sus/sushi',
                    '../test.tree/words/s/swa/swami',
                    '../test.tree/words/s/syl/syllabi',
                    '../test.tree/words/t/tal/tali',
                    '../test.tree/words/t/tan/tandoori',
                    '../test.tree/words/t/tar/tarsi',
                    '../test.tree/words/t/tat/tatami',
                    '../test.tree/words/t/tax/taxi',
                    '../test.tree/words/t/tem/tempi',
                    '../test.tree/words/t/ter/termini',
                    '../test.tree/words/t/tha/thalami',
                    '../test.tree/words/t/the/thesauri',
                    '../test.tree/words/t/thr/thrombi',
                    '../test.tree/words/t/ti/ti',
                    '../test.tree/words/t/tim/timpani',
                    '../test.tree/words/t/tor/torsi',
                    '../test.tree/words/t/tor/tortellini',
                    '../test.tree/words/t/tor/tortoni',
                    '../test.tree/words/t/tsu/tsunami',
                    '../test.tree/words/t/tut/tutti',
                    '../test.tree/words/t/tut/tutti-frutti',
                    '../test.tree/words/u/umb/umbilici',
                    '../test.tree/words/u/ute/uteri',
                    '../test.tree/words/v/ver/vermicelli',
                    '../test.tree/words/v/vil/villi',
                    '../test.tree/words/v/vir/virtuosi',
                    '../test.tree/words/w/wad/wadi',
                    '../test.tree/words/w/wap/wapiti',
                    '../test.tree/words/w/wat/water-ski',
                    '../test.tree/words/x/xi/xi',
                    '../test.tree/words/y/yet/yeti',
                    '../test.tree/words/y/yog/yogi',
                    '../test.tree/words/z/zuc/zucchini'
                ]

            .catch done


    it 'and finally',

        (done) ->

            @timeout 6000

            @run '../test.tree/**/who*'

            .then (r) ->

                done r.should.eql [
                    '../test.tree/words/w/who/whoa',
                    '../test.tree/words/w/who/whodunit',
                    '../test.tree/words/w/who/whoever',
                    '../test.tree/words/w/who/whole',
                    '../test.tree/words/w/who/whole-wheat',
                    '../test.tree/words/w/who/wholehearted',
                    '../test.tree/words/w/who/wholeheartedly',
                    '../test.tree/words/w/who/wholeheartedness',
                    '../test.tree/words/w/who/wholeness',
                    '../test.tree/words/w/who/wholesale',
                    '../test.tree/words/w/who/wholesaler',
                    '../test.tree/words/w/who/wholesome',
                    '../test.tree/words/w/who/wholesomely',
                    '../test.tree/words/w/who/wholesomeness',
                    '../test.tree/words/w/who/wholly',
                    '../test.tree/words/w/who/whom',
                    '../test.tree/words/w/who/whomever',
                    '../test.tree/words/w/who/whomsoever',
                    '../test.tree/words/w/who/whoop',

                    '../test.tree/words/w/who/whoopee',

                    '../test.tree/words/w/who/whooper',
                    '../test.tree/words/w/who/whoops',
                    '../test.tree/words/w/who/whoosh',
                    '../test.tree/words/w/who/whopper',
                    '../test.tree/words/w/who/whopping',
                    '../test.tree/words/w/who/whore',
                    '../test.tree/words/w/who/whorehouse',
                    '../test.tree/words/w/who/whoreish',
                    '../test.tree/words/w/who/whorish',
                    '../test.tree/words/w/who/whorl',
                    '../test.tree/words/w/who/whorled',
                    '../test.tree/words/w/who/whose',
                    '../test.tree/words/w/who/whoso',
                    '../test.tree/words/w/who/whosoever'
                ]

            .catch done

