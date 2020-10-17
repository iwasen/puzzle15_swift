//
//  Puzzle15ViewController.swift
//  puzzle15_pic
//
//  Created by 相沢伸一 on 2020/01/27.
//

import UIKit
import AVKit

class Puzzle15ViewController: UIViewController, OpeningViewDelegate, PieceViewDelegate {
    struct PIECE_INFO {
        var view: PieceView
        var position: Int
    }

    private let PLAY_MODE_NORMAL = 0
    private let PLAY_MODE_EASY = 1
    private let PIECE_WIDTH = 180
    private let PIECE_HEIGHT = 180

    @IBOutlet var openingView: OpeningView!
    @IBOutlet var menuView: UIView!
    @IBOutlet var helpView: UIView!
    @IBOutlet weak var puzzleView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var moveCountLabel: UILabel!
    var completeView: UIView!
    var pieces: [PIECE_INFO] = []
    var playFlag: Bool = false
    var playMode: Int = 0
    var soundBGM: AVAudioPlayer!
    var soundMoveOK: AVAudioPlayer!
    var soundMoveNG: AVAudioPlayer!
    var elapsedTime: Int = 0
    var openingMovieLayer: AVPlayerLayer!
    var completeMovieLayer: AVPlayerLayer!

    var moveCount: Int = 0
    var timer: Timer = Timer()
    
    override func viewDidLoad() {
        // オープニング表示
        view.addSubview(openingView)
        openingView.delegate = self
        var moviePath = Bundle.main.path(forResource: "15puzzle_op", ofType: "mp4")!
        var url = URL(fileURLWithPath: moviePath)
        let openingMovie = AVPlayer.init(url: url)
        NotificationCenter.default.addObserver(self, selector: #selector(endOpeningMovie), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: openingMovie.currentItem)

        openingMovieLayer = AVPlayerLayer.init(player: openingMovie)
        openingMovieLayer.frame = CGRect(x: 0, y: 0, width: 768, height: 700)
        openingView.layer.addSublayer(openingMovieLayer)
        openingMovie.play()
        
        // 完成画面準備
        completeView = UIView.init(frame: puzzleView.bounds)
        moviePath = Bundle.main.path(forResource: "15pazuru_nyako", ofType: "mp4")!
        url = URL(fileURLWithPath: moviePath)
        let completeMovie = AVPlayer.init(url: url)
        completeMovieLayer = AVPlayerLayer.init(player: completeMovie)
        completeMovieLayer.frame = completeView.bounds
        completeView.layer.addSublayer(completeMovieLayer)

        // ピース初期化
        pieces = []
        for i in 0..<16 {
            let view = PieceView.init()
            view.isUserInteractionEnabled = true;
            view.pieceNo = i;
            view.delegate = self;
            puzzleView.addSubview(view)
            
            pieces.append(PIECE_INFO(view: view, position: i))
        }
        
        // サウンド初期化
        soundBGM = initializeSound(sound: "bgm.mp3")
        soundBGM.numberOfLoops = -1;
        soundMoveOK = initializeSound(sound: "動かしたときの音.aif")
        soundMoveNG = initializeSound(sound: "動かせないときの音.aif");
    }

    // オープニングムービー終了処理
    @objc func endOpeningMovie()
    {
        view.addSubview(menuView)
        openingView.removeFromSuperview()
        openingView = nil
    }

    // サウンド初期化
    func initializeSound(sound: String) ->AVAudioPlayer
    {
        let path = Bundle.main.path(forResource: sound, ofType: "")!
        let url = URL(fileURLWithPath: path)
        return try! AVAudioPlayer.init(contentsOf: url)
    }

    func touchPiece(pieceNo: Int) {
        if (playFlag) {
            if (checkAndMovePiece(pieceNo: pieceNo)) {
                // 回数ラベル表示
                moveCount += 1
                setMoveCount(count: moveCount)
                
                // 動かした時の音
                soundMoveOK.currentTime = 0
                soundMoveOK.play()
                
                // アニメーション処理
                UIView.animate(withDuration: 0.2, animations: {
                    var rect = self.pieces[pieceNo].view.frame;
                    rect.origin.x = CGFloat(self.pieces[pieceNo].position % 4 * self.PIECE_WIDTH);
                    rect.origin.y = CGFloat(self.pieces[pieceNo].position / 4 * self.PIECE_HEIGHT);
                    self.pieces[pieceNo].view.frame = rect;
                })
                /*
                var context = UIGraphicsGetCurrentContext();
                UIView.beginAnimations(nil, context: context)
                UIView.setAnimationDuration(0.2)
                var rect = pieces[pieceNo].view.frame;
                rect.origin.x = CGFloat(pieces[pieceNo].position % 4 * PIECE_WIDTH);
                rect.origin.y = CGFloat(pieces[pieceNo].position / 4 * PIECE_HEIGHT);
                pieces[pieceNo].view.frame = rect;
                UIView.commitAnimations()
                */
                // 完成チェック
                if (checkComplete()) {
                    timer.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false, block: {_ in
                        self.endPuzzle()
                    })
                }
            } else {
                // 動かせなかった時の音
                soundMoveNG.currentTime = 0
                soundMoveNG.play()
            }
            
        }
    }

    // 動かせるかチェックし、動かせれば動かす
    func checkAndMovePiece(pieceNo: Int) ->Bool
    {
        let movePosition = pieces[pieceNo].position;
        let blankPosition = pieces[15].position;
        
        let mx = movePosition % 4;
        let my = movePosition / 4;
        let bx = blankPosition % 4;
        let by = blankPosition / 4;
        
        if (my == by) {
            if ((mx > 0 && mx - 1 == bx) || (mx < 3 && mx + 1 == bx)) {
                movePiece(pieceNo: pieceNo)
                return true;
            }
        }
        
        if (mx == bx) {
            if ((my > 0 && my - 1 == by) || (my < 3 && my + 1 == by)) {
                movePiece(pieceNo: pieceNo)
                return true;
            }
        }
        
        return false;
    }

    // 移動回数表示
    func setMoveCount(count: Int)
    {
        moveCount = count;
        moveCountLabel.text = moveCount.description
    }

    // 完成チェック
    func checkComplete() ->Bool
    {
        for i in 0..<15 {
            if (pieces[i].position != i) {
                return false
            }
        }
        return true
    }

    // ピースを移動する
    func movePiece(pieceNo: Int)
    {
        let temp = pieces[pieceNo].position;
        pieces[pieceNo].position = pieces[15].position;
        pieces[15].position = temp;
    }

    // パズル開始処理
    func startPuzzle()
    {
        // 完成ムービー消去
        completeMovieLayer.player?.pause()
        completeView.removeFromSuperview()

        // 最後のピースを非表示
        pieces[15].view.removeFromSuperview()
        
        // ピースを表示
        displayPieces()
        
        // 経過時間
        elapsedTime = 0;
        displayTime()
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: {_ in
            self.displayTime()
        })
        
        // BGM再生
        soundBGM.currentTime = 0
        soundBGM.play()
        
        playFlag = true;
    }

    // パズル終了処理
    func endPuzzle()
    {
        // BGM停止
        soundBGM.stop()
        
        // 経過時間タイマー停止
        timer.invalidate()
        
        playFlag = false;
        
        // 完成ムービー表示用タイマーセット
        playCompleteMovie()
    }

    // 完成ムービー再生
    func playCompleteMovie()
    {
        puzzleView.addSubview(completeView)
        completeView.alpha = 0.0;
    //    completeView.controlStyle = MPMovieControlStyleNone;
        completeMovieLayer.player?.seek(to: CMTime.zero)
        completeMovieLayer.player?.play()
        
        UIView.animate(withDuration: 2.0, animations: {
            self.completeView.alpha = 1.0;
        })
    }

    func touchOpeningView() {
        openingMovieLayer.player?.pause()
        endOpeningMovie()
    }

    // 全ピースを表示
    func displayPieces()
    {
        for i in 0..<16 {
            pieces[i].view.frame = CGRect(x: pieces[i].position % 4 * PIECE_WIDTH, y: pieces[i].position / 4 * PIECE_HEIGHT, width: PIECE_WIDTH, height: PIECE_WIDTH);
        }
    }

    // 経過時間表示
    func displayTime()
    {
        timeLabel.text = String(format: "%02d:%02d", elapsedTime / 60, elapsedTime % 60)
        elapsedTime += 1;
    }

    // ピースをシャッフル
    func sufflePieces()
    {
        // 乱数初期化
//        srand(UInt32(time(nil)));

        // 位置を初期化
        for i in 0..<16 {
            pieces[i].position = i;
        }
        
        // 100回ピースを入れ替え
        for _ in 0..<100 {
            let r1 = Int.random(in: 0..<15)
            var r2: Int
            repeat {
                r2 = Int.random(in: 0..<15)
            } while (r1 == r2);
            
            let temp = pieces[r1].position;
            pieces[r1].position = pieces[r2].position;
            pieces[r2].position = temp;
            _ = checkAndMovePiece(pieceNo: r1)
        }
    }

    // easyボタン処理
    @IBAction func easyButton(sender: AnyObject)
    {
        menuView.removeFromSuperview()
        playMode = PLAY_MODE_EASY;
        
        // ピース画像を表示
        loadPieces()
        displayPieces()
    }

    // normalボタン処理
    @IBAction func normalButton(sender: AnyObject)
    {
        menuView.removeFromSuperview()
        playMode = PLAY_MODE_NORMAL;
        
        // ピース画像を表示
        loadPieces()
        displayPieces()
    }

    // helpボタン処理
    @IBAction func helpButton(sender: AnyObject)
    {
        self.view.addSubview(helpView)
    }

    // 開始ボタン処理
    @IBAction func startButton(sender: AnyObject)
    {
        // ピースをシャッフル
        sufflePieces()
        startPuzzle()
        
        // 回数初期化
        setMoveCount(count: 0)
    }

    // ピース画像を読み込み
    func loadPieces()
    {
        let format = (playMode == PLAY_MODE_EASY) ? "n%02de" : "n%02d"
        for i in 0..<16 {
            let tempStr = String(format: format, i + 1)
            let path = Bundle.main.path(forResource: tempStr, ofType: "png")!
            pieces[i].view.image = UIImage(named: path)
        }
    }
    // テストボタン処理
    @IBAction func testButton(sender: AnyObject)
    {
        for i in 0..<16 {
            pieces[i].position = i
        }
        
        movePiece(pieceNo: 14)
        movePiece(pieceNo: 13)
        startPuzzle()
        
        // 回数初期化
        setMoveCount(count: 0)
    }

    // backボタン処理
    @IBAction func backButton(sender: AnyObject)
    {
        helpView.removeFromSuperview()
    }

    // iボタン処理
    @IBAction func infoButton(sender: AnyObject)
    {
        self.view.addSubview(helpView)
    }

    // メニューボタン処理
    @IBAction func menuButton(sender: AnyObject)
    {
        // メニュー画面表示
        self.view.addSubview(menuView)

        // ピース消去と初期化
        for i in 0..<16 {
            pieces[i].view.removeFromSuperview()
            puzzleView.addSubview(pieces[i].view)
            pieces[i].position = i;
        }

        // 完成ムービー消去
        completeMovieLayer.player?.pause()
        completeView.removeFromSuperview()
        
        // サウンド停止
        soundBGM.stop()
        
        // タイマー初期化
        timer.invalidate()
        timeLabel.text = "00:00"

        //　移動回数初期化
        setMoveCount(count: 0)
    }
}

/*
 #define PLAY_MODE_NORMAL    0
 #define PLAY_MODE_EASY        1

 #define PIECE_WIDTH        180
 #define PIECE_HEIGHT    180

 typedef struct _PIECE_INFO {
     PieceView *view;
     int position;
 } PIECE_INFO;

 @implementation Puzzle15ViewController {
     IBOutlet OpeningView *openingView;
     IBOutlet UIView *menuView;
     IBOutlet UIView *helpView;
     IBOutlet UIView *puzzleView;
     UIView *completeView;
     PIECE_INFO pieces[16];
     BOOL playFlag;
     int playMode;
     AVAudioPlayer *soundBGM;
     AVAudioPlayer *soundMoveOK;
     AVAudioPlayer *soundMoveNG;
     int elapsedTime;
     IBOutlet UILabel *timeLabel;
     AVPlayerLayer *openingMovieLayer;
     AVPlayerLayer *completeMovieLayer;

     int moveCount;
     IBOutlet UILabel *moveCountLabel;
     NSTimer *timer;
 }

 // 初期化処理
 - (void)viewDidLoad {
     [super viewDidLoad];

     // オープニング表示
     [self.view addSubview:openingView];
     openingView.delegate = self;
     NSString *moviePath = [[NSBundle mainBundle] pathForResource:@"15puzzle_op" ofType:@"mp4"];
     NSURL *url = [NSURL fileURLWithPath:moviePath];
     AVPlayer *openingMovie = [[AVPlayer alloc] initWithURL:url];
     [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(endOpeningMovie)
                                                  name:AVPlayerItemDidPlayToEndTimeNotification
                                                object:openingMovie.currentItem];
     openingMovieLayer = [AVPlayerLayer playerLayerWithPlayer:openingMovie];
     [openingMovieLayer setFrame:CGRectMake(0, 0, 768, 700)];
     [openingView.layer addSublayer:openingMovieLayer];
 //    self.openingMovie.controlStyle = MPMovieControlStyleNone;
     [openingMovie play];
     
     // 完成画面準備
     completeView = [[UIView alloc] initWithFrame:puzzleView.bounds];
     moviePath = [[NSBundle mainBundle] pathForResource:@"15pazuru_nyako" ofType:@"mp4"];
     url = [NSURL fileURLWithPath:moviePath];
     AVPlayer *completeMovie = [[AVPlayer alloc] initWithURL:url];
     completeMovieLayer = [AVPlayerLayer playerLayerWithPlayer:completeMovie];
     [completeMovieLayer setFrame:[completeView bounds]];
     [completeView.layer addSublayer:completeMovieLayer];

     // ピース初期化
     for (int i = 0; i < 16; i++) {
         PieceView *view = [[PieceView alloc] init];
         view.userInteractionEnabled = YES;
         view.pieceNo = i;
         view.delegate = self;
         [puzzleView addSubview:view];
         pieces[i].view = view;
         pieces[i].position = i;
     }
     
     // サウンド初期化
     soundBGM = [self initializeSound:@"bgm.mp3"];
     soundBGM.numberOfLoops = -1;
     soundMoveOK = [self initializeSound:@"動かしたときの音.aif"];
     soundMoveNG = [self initializeSound:@"動かせないときの音.aif"];
 }

 // オープニングムービー終了処理
 - (void)endOpeningMovie
 {
     [self.view addSubview:menuView];
     [openingView removeFromSuperview];
     openingView  = nil;
 }

 - (void)touchOpeningView
 {
     [openingMovieLayer.player pause];
     [self endOpeningMovie];
 }

 // easyボタン処理
 - (IBAction)easyButton:(id)sender
 {
     [menuView removeFromSuperview];
     playMode = PLAY_MODE_EASY;
     
     // ピース画像を表示
     [self loadPieces];
     [self displayPieces];
 }

 // normalボタン処理
 - (IBAction)normalButton:(id)sender
 {
     [menuView removeFromSuperview];
     playMode = PLAY_MODE_NORMAL;
     
     // ピース画像を表示
     [self loadPieces];
     [self displayPieces];
 }

 // helpボタン処理
 - (IBAction)helpButton:(id)sender
 {
     [self.view addSubview:helpView];
 }

 // 開始ボタン処理
 - (IBAction)startButton:(id)sender
 {
     // ピースをシャッフル
     [self sufflePieces];
     [self startPuzzle];
     
     // 回数初期化
     [self setMoveCount:0];
 }

 // テストボタン処理
 - (IBAction)testButton:(id)sender
 {
     for (int i = 0; i < 16; i++)
         pieces[i].position = i;
     
     [self movePiece:14];
     [self movePiece:13];
     [self startPuzzle];
     
     // 回数初期化
     [self setMoveCount:0];
 }

 // backボタン処理
 - (IBAction)backButton:(id)sender
 {
     [helpView removeFromSuperview];
 }

 // iボタン処理
 - (IBAction)infoButton:(id)sender
 {
     [self.view addSubview:helpView];
 }

 // メニューボタン処理
 - (IBAction)menuButton:(id)sender
 {
     // メニュー画面表示
     [self.view addSubview:menuView];

     // ピース消去と初期化
     for (int i = 0; i < 16; i++) {
         [pieces[i].view removeFromSuperview];
         [puzzleView addSubview:pieces[i].view];
         pieces[i].position = i;
     }

     // 完成ムービー消去
     [completeMovieLayer.player pause];
     [completeView removeFromSuperview];
     
     // サウンド停止
     [soundBGM stop];
     
     // タイマー初期化
     [timer invalidate];
     timer = nil;
     timeLabel.text = [NSString stringWithFormat:@"00:00"];

     //　移動回数初期化
     [self setMoveCount:0];
 }

 // パズル開始処理
 - (void)startPuzzle
 {
     // 完成ムービー消去
     [completeMovieLayer.player pause];
     [completeView removeFromSuperview];

     // 最後のピースを非表示
     [pieces[15].view removeFromSuperview];
     
     // ピースを表示
     [self displayPieces];
     
     // 経過時間
     elapsedTime = 0;
     [self displayTime];
     [timer invalidate];
     timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
     
     // BGM再生
     soundBGM.currentTime = 0;
     [soundBGM play];
     
     playFlag = YES;
 }

 // パズル終了処理
 - (void)endPuzzle
 {
     // 右下のピースを表示
     //    [puzzleView addSubview:pieces[15].view];
     
     // BGM停止
     [soundBGM stop];
     
     // 経過時間タイマー停止
     [timer invalidate];
     timer = nil;
     
     playFlag = NO;
     
     // 完成ムービー表示用タイマーセット
 //    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(playCompleteMovie) userInfo:nil repeats:NO];
     [self playCompleteMovie];
 }

 // ピース画像を読み込み
 - (void)loadPieces
 {
     NSString *tempStr;
     NSString *path;

     NSString *format = (playMode == PLAY_MODE_EASY) ? @"n%02de" : @"n%02d";
     for (int i = 0; i < 16; i++) {
         tempStr = [NSString stringWithFormat:format, i + 1];
         path = [[NSBundle mainBundle] pathForResource:tempStr ofType:@"png"];
         pieces[i].view.image = [UIImage imageWithContentsOfFile:path];
     }
 }

 // 全ピースを表示
 - (void)displayPieces
 {
     CGRect rect;
     
     for (int i = 0; i < 16; i++) {
         rect.origin.x = pieces[i].position % 4 * PIECE_WIDTH;
         rect.origin.y = pieces[i].position / 4 * PIECE_HEIGHT;
         rect.size = CGSizeMake(PIECE_WIDTH, PIECE_HEIGHT);
         pieces[i].view.frame = rect;
     }
 }

 // ピースをシャッフル
 - (void)sufflePieces
 {
     int i;
     int r1, r2;
     int temp;

     // 乱数初期化
     srand((uint)time(NULL));

     // 位置を初期化
     for (int i = 0; i < 16; i++)
         pieces[i].position = i;
     
     // 100回ピースを入れ替え
     for (i = 0; i < 100; i++) {
         r1 = rand() % 15;
         do {
             r2 = rand() % 15;
         } while (r1 == r2);
         
         temp = pieces[r1].position;
         pieces[r1].position = pieces[r2].position;
         pieces[r2].position = temp;
         [self checkAndMovePiece:r1];
     }
 }

 // 動かせるかチェックし、動かせれば動かす
 - (BOOL)checkAndMovePiece:(int)pieceNo
 {
     int movePosition = pieces[pieceNo].position;
     int blankPosition = pieces[15].position;
     
     int mx = movePosition % 4;
     int my = movePosition / 4;
     int bx = blankPosition % 4;
     int by = blankPosition / 4;
     
     if (my == by) {
         if ((mx > 0 && mx - 1 == bx) || (mx < 3 && mx + 1 == bx)) {
             [self movePiece:pieceNo];
             return YES;
         }
     }
     
     if (mx == bx) {
         if ((my > 0 && my - 1 == by) || (my < 3 && my + 1 == by)) {
             [self movePiece:pieceNo];
             return YES;
         }
     }
     
     return NO;
 }

 // ピースを移動する
 - (void)movePiece:(int)pieceNo
 {
     int temp;
     
     temp = pieces[pieceNo].position;
     pieces[pieceNo].position = pieces[15].position;
     pieces[15].position = temp;
 }

 // ピースをタッチされた時の処理（PieceViewから呼ばれる）
 - (void)touchPiece:(int)pieceNo
 {
     if (playFlag) {
         if ([self checkAndMovePiece:pieceNo]) {
             
             // 回数ラベル表示
             [self setMoveCount:++moveCount];
             
             // 動かした時の音
             soundMoveOK.currentTime = 0;
             [soundMoveOK play];
             
             // アニメーション処理
             CGContextRef context = UIGraphicsGetCurrentContext();
             [UIView beginAnimations:nil context:context];
             [UIView setAnimationDuration:0.2];
             CGRect rect = pieces[pieceNo].view.frame;
             rect.origin.x = pieces[pieceNo].position % 4 * PIECE_WIDTH;
             rect.origin.y = pieces[pieceNo].position / 4 * PIECE_HEIGHT;
             pieces[pieceNo].view.frame = rect;
             [UIView commitAnimations];
             
             // 完成チェック
             if ([self checkComplete]) {
                 [timer invalidate];
                 timer = [NSTimer scheduledTimerWithTimeInterval:0.8 target:self selector:@selector(endPuzzle) userInfo:nil repeats:YES];
 //                [self endPuzzle];
             }
         } else {
             // 動かせなかった時の音
             soundMoveNG.currentTime = 0;
             [soundMoveNG play];
         }
         
     }
 }

 // サウンド初期化
 - (AVAudioPlayer *)initializeSound:(NSString *)sound
 {
     NSString *path = [[NSBundle mainBundle] pathForResource:sound ofType:@""];
     NSURL *url = [NSURL fileURLWithPath:path];
     return [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
 }

 // 経過時間表示
 - (void)displayTime
 {
     timeLabel.text = [NSString stringWithFormat:@"%02d:%02d", elapsedTime / 60, elapsedTime % 60];
     elapsedTime++;
 }

 // 移動回数表示
 - (void)setMoveCount:(int)count
 {
     moveCount = count;
     moveCountLabel.text = [NSString stringWithFormat:@"%d", moveCount];
 }


 // 完成チェック
 - (BOOL)checkComplete
 {
     for (int i = 0; i < 15; i++) {
         if (pieces[i].position != i)
             return NO;
     }
     return YES;
 }

 // 完成ムービー再生
 - (void)playCompleteMovie
 {
     [puzzleView addSubview:completeView];
     completeView.alpha = 0.0;
 //    completeView.controlStyle = MPMovieControlStyleNone;
     [completeMovieLayer.player seekToTime:kCMTimeZero];
     [completeMovieLayer.player play];
     
     [UIView beginAnimations:@"CompleteMovie" context:nil];
     [UIView setAnimationDuration:2.0];
     completeView.alpha = 1.0;
     [UIView commitAnimations];
 }

 @end

 */
