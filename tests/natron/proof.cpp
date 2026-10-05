// SPDX-License-Identifier: GPL-3.0-or-later
// External test plugins only; Natron remains the real host and renderer.
// ABI: Natron's pinned libs/OpenFX/include, revision 2303ff811bee3ffe085287602f684fe5fe5357e0.
#define OFX_EXTENSIONS_TUTTLE
#include <ofxImageEffect.h>
#include <ofxParam.h>
#include <ofxProperty.h>
#include <cstdio>
#include <cstring>
#include <exception>

static OfxHost* host = nullptr;
static const OfxPropertySuiteV1* props = nullptr;
static const OfxImageEffectSuiteV1* effects = nullptr;
static const OfxParameterSuiteV1* params = nullptr;
static void checked(OfxStatus s) { if (s != kOfxStatOK) throw s; }
#define CHECK(call) checked(call)

struct Image {
    OfxPropertySetHandle handle = nullptr;
    unsigned char* pixels = nullptr;
    int bounds[4] = {}, stride = 0;
    Image(OfxImageEffectHandle effect, const char* name, double time) {
        OfxImageClipHandle clip = nullptr;
        CHECK(effects->clipGetHandle(effect, name, &clip, nullptr));
        CHECK(effects->clipGetImage(clip, time, nullptr, &handle));
        try {
            void* data = nullptr;
            const char *depth = nullptr, *components = nullptr;
            CHECK(props->propGetPointer(handle, kOfxImagePropData, 0, &data));
            CHECK(props->propGetIntN(handle, kOfxImagePropBounds, 4, bounds));
            CHECK(props->propGetInt(handle, kOfxImagePropRowBytes, 0, &stride));
            CHECK(props->propGetString(handle, kOfxImageEffectPropPixelDepth, 0, &depth));
            CHECK(props->propGetString(handle, kOfxImageEffectPropComponents, 0, &components));
            if (!data || std::strcmp(depth, kOfxBitDepthByte) ||
                std::strcmp(components, kOfxImageComponentRGBA) ||
                bounds[0] != 0 || bounds[1] != 0 || bounds[2] != 2 || bounds[3] != 2)
                throw kOfxStatErrFormat;
            pixels = static_cast<unsigned char*>(data);
        } catch (...) { effects->clipReleaseImage(handle); handle = nullptr; throw; }
    }
    ~Image() { if (handle) effects->clipReleaseImage(handle); }
    unsigned char* at(int x, int y) { return pixels + y * stride + x * 4; }
};

static void describeClip(OfxImageEffectHandle effect, const char* name, bool optional) {
    OfxPropertySetHandle p = nullptr;
    CHECK(effects->clipDefine(effect, name, &p));
    CHECK(props->propSetString(p, kOfxImageEffectPropSupportedComponents, 0, kOfxImageComponentRGBA));
    CHECK(props->propSetInt(p, kOfxImageEffectPropSupportsTiles, 0, 0));
    CHECK(props->propSetInt(p, kOfxImageClipPropOptional, 0, optional ? 1 : 0));
}

static OfxStatus dispatch(bool writer, const char* action, const void* handle,
                          OfxPropertySetHandle in, OfxPropertySetHandle out) {
    try {
        auto effect = static_cast<OfxImageEffectHandle>(const_cast<void*>(handle));
        if (!std::strcmp(action, kOfxActionLoad)) {
            props = static_cast<const OfxPropertySuiteV1*>(host->fetchSuite(host->host, kOfxPropertySuite, 1));
            effects = static_cast<const OfxImageEffectSuiteV1*>(host->fetchSuite(host->host, kOfxImageEffectSuite, 1));
            params = static_cast<const OfxParameterSuiteV1*>(host->fetchSuite(host->host, kOfxParameterSuite, 1));
            return props && effects && params ? kOfxStatOK : kOfxStatErrMissingHostFeature;
        }
        if (!std::strcmp(action, kOfxActionCreateInstance) ||
            !std::strcmp(action, kOfxActionDestroyInstance) ||
            !std::strcmp(action, kOfxActionUnload)) return kOfxStatOK;
        if (!std::strcmp(action, kOfxActionDescribe)) {
            OfxPropertySetHandle p = nullptr;
            CHECK(effects->getPropertySet(effect, &p));
            CHECK(props->propSetString(p, kOfxPropLabel, 0, writer ? "Natron Proof Writer" : "Natron Proof Generator"));
            CHECK(props->propSetString(p, kOfxImageEffectPropSupportedContexts, 0,
                                      writer ? kOfxImageEffectContextWriter : kOfxImageEffectContextGenerator));
            CHECK(props->propSetString(p, kOfxImageEffectPropSupportedPixelDepths, 0, kOfxBitDepthByte));
            CHECK(props->propSetInt(p, kOfxImageEffectPropSupportsTiles, 0, 0));
            CHECK(props->propSetInt(p, kOfxImageEffectPropSupportsMultiResolution, 0, 0));
            CHECK(props->propSetInt(p, kOfxImageEffectPluginPropFieldRenderTwiceAlways, 0, 0));
            CHECK(props->propSetString(p, kOfxImageEffectPluginRenderThreadSafety, 0, kOfxImageEffectRenderUnsafe));
            if (writer) CHECK(props->propSetString(p, "TuttleOfxImageEffectPropSupportedExtensions", 0, "ppm"));
            return kOfxStatOK;
        }
        if (!std::strcmp(action, kOfxImageEffectActionDescribeInContext)) {
            describeClip(effect, kOfxImageEffectSimpleSourceClipName, !writer);
            describeClip(effect, kOfxImageEffectOutputClipName, false);
            if (writer) {
                OfxParamSetHandle set = nullptr;
                OfxPropertySetHandle p = nullptr;
                CHECK(effects->getParamSet(effect, &set));
                CHECK(params->paramDefine(set, kOfxParamTypeString, kOfxImageEffectFileParamName, &p));
                CHECK(props->propSetString(p, kOfxParamPropStringMode, 0, kOfxParamStringIsFilePath));
                CHECK(props->propSetInt(p, kOfxParamPropStringFilePathExists, 0, 0));
                CHECK(props->propSetInt(p, kOfxParamPropAnimates, 0, 0));
                CHECK(props->propSetString(p, kOfxParamPropDefault, 0, ""));
            }
            return kOfxStatOK;
        }
        if (!writer && !std::strcmp(action, kOfxImageEffectActionGetRegionOfDefinition)) {
            const double rod[4] = {0., 0., 2., 2.};
            CHECK(props->propSetDoubleN(out, kOfxImageEffectPropRegionOfDefinition, 4, rod));
            return kOfxStatOK;
        }
        if (!std::strcmp(action, kOfxImageEffectActionRender)) {
            double time = 0.;
            CHECK(props->propGetDouble(in, kOfxPropTime, 0, &time));
            if (time != 1.) throw kOfxStatErrValue;
            if (!writer) {
                Image image(effect, kOfxImageEffectOutputClipName, time);
                // OFX y=0 is bottom: top red/green, bottom blue/white.
                const unsigned char rgba[2][2][4] = {
                    {{0, 0, 255, 255}, {255, 255, 255, 255}},
                    {{255, 0, 0, 255}, {0, 255, 0, 255}}
                };
                for (int y = 0; y != 2; ++y)
                    for (int x = 0; x != 2; ++x) std::memcpy(image.at(x, y), rgba[y][x], 4);
            } else {
                Image image(effect, kOfxImageEffectSimpleSourceClipName, time);
                OfxParamSetHandle set = nullptr;
                OfxParamHandle filename = nullptr;
                char* path = nullptr;
                CHECK(effects->getParamSet(effect, &set));
                CHECK(params->paramGetHandle(set, kOfxImageEffectFileParamName, &filename, nullptr));
                CHECK(params->paramGetValue(filename, &path));
                if (!path || !*path) throw kOfxStatErrValue;
                // File data comes only from the actual host-delivered Source image.
                unsigned char ppm[23] = {'P', '6', '\n', '2', ' ', '2', '\n', '2', '5', '5', '\n'};
                int offset = 11;
                for (int y = 1; y >= 0; --y)
                    for (int x = 0; x != 2; ++x) {
                        std::memcpy(ppm + offset, image.at(x, y), 3); offset += 3;
                    }
                FILE* file = std::fopen(path, "wb");
                if (!file) throw kOfxStatFailed;
                const bool wrote = std::fwrite(ppm, 1, sizeof ppm, file) == sizeof ppm;
                const bool closed = std::fclose(file) == 0;
                if (!wrote || !closed) throw kOfxStatFailed;
            }
            return kOfxStatOK;
        }
        return kOfxStatReplyDefault;
    } catch (OfxStatus status) { return status; }
      catch (...) { return kOfxStatFailed; }
}
static void setHost(OfxHost* value) { host = value; }
static OfxStatus generator(const char* a, const void* h, OfxPropertySetHandle i, OfxPropertySetHandle o) {
    return dispatch(false, a, h, i, o);
}
static OfxStatus writer(const char* a, const void* h, OfxPropertySetHandle i, OfxPropertySetHandle o) {
    return dispatch(true, a, h, i, o);
}
static OfxPlugin plugins[] = {
    {kOfxImageEffectPluginApi, 1, "org.guix.NatronProofGenerator", 1, 0, setHost, generator},
    {kOfxImageEffectPluginApi, 1, "org.guix.NatronProofWriter", 1, 0, setHost, writer}
};
extern "C" {
OfxExport int OfxGetNumberOfPlugins() { return 2; }
OfxExport OfxPlugin* OfxGetPlugin(int i) { return i >= 0 && i < 2 ? &plugins[i] : nullptr; }
}
