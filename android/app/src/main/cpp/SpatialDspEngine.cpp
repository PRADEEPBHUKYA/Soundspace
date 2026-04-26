#include <jni.h>
#include <vector>
#include <map>
#include <string>
#include <mutex>
#include <cmath>
#include <algorithm>
#include <oboe/Oboe.h>

#define SR 48000
#define PI 3.14159265f
#define MAX_DLY SR

// ── Circular buffer ─────────────────────────────────────────────────────────
struct Ring {
    std::vector<int16_t> b; size_t h=0,t=0,cap;
    explicit Ring(size_t n): b(n,0),cap(n){}
    void push(int16_t v){ b[h]=v; h=(h+1)%cap; }
    int16_t pop(){ int16_t v=b[t]; t=(t+1)%cap; return v; }
    size_t avail() const { return h>=t?h-t:cap-t+h; }
};

// ── Biquad ───────────────────────────────────────────────────────────────────
struct Biquad {
    float b0=1,b1=0,b2=0,a1=0,a2=0,z1=0,z2=0;
    void lp(float f,float Q=.707f){ _set(0,f,Q); }
    void hp(float f,float Q=.707f){ _set(1,f,Q); }
    void bp(float f,float Q=.5f)  { _set(2,f,Q); }
    void _set(int t,float f,float Q){
        float w=2*PI*f/SR,sn=sinf(w),cs=cosf(w),al=sn/(2*Q);
        float B0,B1,B2,A0=1+al,A1=-2*cs,A2=1-al;
        if(t==0){B0=(1-cs)/2;B1=1-cs;B2=B0;}
        else if(t==1){B0=(1+cs)/2;B1=-(1+cs);B2=B0;}
        else{B0=al;B1=0;B2=-al;}
        b0=B0/A0;b1=B1/A0;b2=B2/A0;a1=A1/A0;a2=A2/A0;
    }
    float proc(float x){ float y=b0*x+z1; z1=b1*x-a1*y+z2; z2=b2*x-a2*y; return y; }
};

// ── Engine ───────────────────────────────────────────────────────────────────
struct Src { float x=.5f,y=.5f,gain=1.f; bool muted=false; };

class Engine: public oboe::AudioStreamCallback {
public:
    Ring ring{SR/5};
    std::mutex mx;
    std::map<std::string,Src> src{{"bass",{}},{"vocal",{}},{"treble",{}},{"lead",{}}};
    Biquad fb,fv,fl,ft;
    std::vector<float> rvb{MAX_DLY,0.f};
    int rw=0;
    float room=.4f,width=.8f;
    float eq[5]={0,0,0,0,0};
    oboe::ManagedStream st;

    Engine(){ fb.lp(250); fv.bp(1375); fl.bp(4500); ft.hp(6500); }

    void init(){
        oboe::AudioStreamBuilder b;
        b.setDirection(oboe::Direction::Output)
         ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
         ->setSharingMode(oboe::SharingMode::Exclusive)
         ->setFormat(oboe::AudioFormat::Float)
         ->setChannelCount(2)->setSampleRate(SR)->setCallback(this);
        b.openStream(st);
        if(st) st->requestStart();
    }

    void feed(int16_t* d,int n){ std::lock_guard<std::mutex> g(mx); for(int i=0;i<n;i++) ring.push(d[i]); }
    void updSrc(const std::string& id,float x,float y,float g,bool m){ std::lock_guard<std::mutex> l(mx); src[id]={x,y,g,m}; }
    void setRoom(float v){ std::lock_guard<std::mutex> l(mx); room=v; }
    void setWidth(float v){ std::lock_guard<std::mutex> l(mx); width=v; }
    void setEq(float* b){ std::lock_guard<std::mutex> l(mx); for(int i=0;i<5;i++) eq[i]=b[i]; }
    void stop(){ if(st){st->stop();st->close();} }

    void pan(float s,const std::string& id,float& L,float& R){
        auto it=src.find(id); Src p=(it!=src.end())?it->second:Src{};
        if(p.muted) return;
        float vol=1.f-p.y*.65f;
        float pw=p.x; // 0=L 1=R
        float l=sqrtf(1.f-pw), r=sqrtf(pw);
        float mid=(l+r)*.5f;
        l=mid+(l-mid)*width; r=mid+(r-mid)*width;
        L+=s*vol*l*p.gain; R+=s*vol*r*p.gain;
    }

    oboe::DataCallbackResult onAudioReady(oboe::AudioStream*,void* data,int32_t frames) override {
        float* out=static_cast<float*>(data);
        std::lock_guard<std::mutex> g(mx);
        for(int i=0;i<frames;i++){
            float mono=0;
            if(ring.avail()>=2){ float l=ring.pop()/32768.f,r=ring.pop()/32768.f; mono=(l+r)*.5f; }
            float bass=fb.proc(mono),vocal=fv.proc(mono),lead=fl.proc(mono),treble=ft.proc(mono);
            float L=0,R=0;
            pan(bass,"bass",L,R); pan(vocal,"vocal",L,R); pan(lead,"lead",L,R); pan(treble,"treble",L,R);
            // Reverb
            int di=(int)(room*.09f*SR); if(di<1) di=1;
            int ri=(rw-di+MAX_DLY)%MAX_DLY;
            float rv=rvb[ri], fb2=.22f+room*.42f;
            rvb[rw]=(L+R)*.5f+rv*fb2; rw=(rw+1)%MAX_DLY;
            float wet=room*.55f;
            L=L*(1-wet)+rv*wet; R=R*(1-wet)+rv*wet;
            out[i*2]  =std::clamp(L,-1.f,1.f);
            out[i*2+1]=std::clamp(R,-1.f,1.f);
        }
        return oboe::DataCallbackResult::Continue;
    }
};

static Engine* E=nullptr;

#define JNI(name) extern "C" JNIEXPORT void JNICALL Java_com_example_soundspace_service_AudioCaptureService_##name

JNI(nativeInit)(JNIEnv*,jclass){ if(!E){E=new Engine();E->init();} }
JNI(nativeFeed)(JNIEnv* env,jclass,jshortArray d,jint n){
    if(!E) return; jshort* p=env->GetShortArrayElements(d,nullptr);
    E->feed(reinterpret_cast<int16_t*>(p),n);
    env->ReleaseShortArrayElements(d,p,JNI_ABORT);
}
JNI(nativeUpdateParams)(JNIEnv* env,jclass,jstring id,jfloat x,jfloat y,jfloat g,jboolean m){
    if(!E) return; const char* c=env->GetStringUTFChars(id,nullptr);
    E->updSrc(std::string(c),x,y,g,(bool)m);
    env->ReleaseStringUTFChars(id,c);
}
JNI(nativeSetRoomSize)(JNIEnv*,jclass,jfloat v){ if(E) E->setRoom(v); }
JNI(nativeSetStereoWidth)(JNIEnv*,jclass,jfloat v){ if(E) E->setWidth(v); }
JNI(nativeSetEq)(JNIEnv* env,jclass,jfloatArray b){
    if(!E) return; jfloat* f=env->GetFloatArrayElements(b,nullptr);
    E->setEq(f); env->ReleaseFloatArrayElements(b,f,JNI_ABORT);
}
JNI(nativeStop)(JNIEnv*,jclass){ if(E){E->stop();delete E;E=nullptr;} }
