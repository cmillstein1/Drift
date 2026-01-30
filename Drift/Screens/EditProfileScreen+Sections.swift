//
//  EditProfileScreen+Sections.swift
//  Drift
//
//  Edit form sections for EditProfileScreen
//

import SwiftUI
import DriftBackend
import UniformTypeIdentifiers

extension EditProfileScreen {

    // MARK: - Photos Section

    var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Photos & Videos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoalColor.opacity(0.6))

            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let spacing: CGFloat = 12
                let totalSpacing = spacing * 2
                let itemWidth = (availableWidth - totalSpacing) / 3
                let itemHeight = itemWidth * 4 / 3

                photoGrid(
                    itemWidth: itemWidth,
                    itemHeight: itemHeight,
                    spacing: spacing
                )
            }
            .frame(height: (UIScreen.main.bounds.width - 64) / 3 * 4 / 3 * 2 + 12)

            Text("Tap to edit, drag to reorder")
                .font(.system(size: 12))
                .foregroundColor(charcoalColor.opacity(0.5))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    func photoGrid(itemWidth: CGFloat, itemHeight: CGFloat, spacing: CGFloat) -> some View {
        let gridColumns = [
            GridItem(.fixed(itemWidth), spacing: spacing),
            GridItem(.fixed(itemWidth), spacing: spacing),
            GridItem(.fixed(itemWidth), spacing: spacing)
        ]
        return LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                photoSlot(at: index, width: itemWidth, height: itemHeight)
            }
        }
    }

    func photoSlot(at index: Int, width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            EditPhotoSlotWithStroke(
                index: index,
                photoUrl: index < photos.count ? photos[index] : nil,
                previewImage: photoImages[index],
                isUploading: isUploadingPhoto == index,
                isMainPhoto: index == 0,
                showMainBadge: false,
                onSelect: { selectedPhotoIndex = index },
                onRemove: { removePhoto(at: index) }
            )
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if index == 0 {
                EditProfileMainBadgeView()
                    .padding(.top, 18)
                    .padding(.leading, 18)
            }
        }
        .frame(width: width, height: height)
        .opacity(draggedPhoto == index ? 0.6 : 1.0)
        .scaleEffect(draggedPhoto == index ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: draggedPhoto)
        .contentShape(Rectangle())
        .onDrag {
            draggedPhoto = index
            return NSItemProvider(object: "\(index)" as NSString)
        }
        .onDrop(of: [.text], delegate: EditProfilePhotoDropDelegate(
            sourceIndex: draggedPhoto ?? index,
            destinationIndex: index,
            photos: $photos,
            photoImages: $photoImages,
            draggedPhoto: $draggedPhoto
        ))
    }

    // MARK: - Van Life Essentials Section

    var vanLifeEssentialsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Van Life Essentials")

            Divider().background(Color.gray.opacity(0.1))

            NavigationLink(destination: NameEditorView(name: $name)) {
                ProfileEditRow(title: "Name", value: name.isEmpty ? "Add your name" : name)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { hideTabBar() })

            Divider().background(Color.gray.opacity(0.1))

            NavigationLink(destination: AgeEditorView(age: $age, birthday: $birthday)) {
                ProfileEditRow(title: "Age", value: age.isEmpty ? "Add your age" : age)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { hideTabBar() })

            Divider().background(Color.gray.opacity(0.1))

            NavigationLink(destination: LocationMapPickerView(location: $currentLocation)) {
                ProfileEditRow(title: "Current Location", value: currentLocation.isEmpty ? "Add location" : currentLocation)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { hideTabBar() })

            Divider().background(Color.gray.opacity(0.1))

            NavigationLink(destination: RigDetailsView(rigInfo: $rigInfo)) {
                ProfileEditRow(title: "The Rig", value: rigInfo.isEmpty ? "Add your rig info" : rigInfo)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { hideTabBar() })

            Divider().background(Color.gray.opacity(0.1))

            ProfileEditRow(title: "Travel Pace", value: travelPace.displayName, onTap: { showTravelPaceEditor = true })
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - My Journey Section

    var myJourneySection: some View {
        VStack(spacing: 0) {
            sectionHeader("My Journey")

            Divider().background(Color.gray.opacity(0.1))

            NavigationLink(destination: AboutEditorView(about: $about)) {
                ProfileEditRow(title: "About", value: about.isEmpty ? "Add your answer" : about, isMultiline: true)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { hideTabBar() })

            if !promptAnswers.isEmpty {
                ForEach(Array(promptAnswers.enumerated()), id: \.offset) { index, promptAnswer in
                    Divider().background(Color.gray.opacity(0.1))

                    Button(action: {
                        selectedPromptIndex = index
                        showPromptEditor = true
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(promptAnswer.prompt)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(charcoalColor)
                            Text(promptAnswer.answer)
                                .font(.system(size: 14))
                                .foregroundColor(charcoalColor.opacity(0.6))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if promptAnswers.count < Self.maxPrompts {
                Divider().background(Color.gray.opacity(0.1))

                Button(action: {
                    selectedPromptIndex = nil
                    showPromptEditor = true
                }) {
                    HStack {
                        Text("Add a prompt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.4))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(charcoalColor.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Travel Plans Section

    var travelPlansSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Travel Plans")

            Divider().background(Color.gray.opacity(0.1))

            NavigationLink(destination: TravelPlansEditorView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upcoming Destinations")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(charcoalColor)
                        Text(travelStopsCount > 0 ? "\(travelStopsCount) destination\(travelStopsCount == 1 ? "" : "s") planned" : "Add your travel plans")
                            .font(.system(size: 14))
                            .foregroundColor(travelStopsCount > 0 ? charcoalColor.opacity(0.6) : charcoalColor.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(charcoalColor.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { hideTabBar() })
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Lifestyle Section

    var lifestyleSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Lifestyle")

            Divider().background(Color.gray.opacity(0.1))

            ProfileEditRow(title: "Work Style", value: workStyle?.displayName ?? "Add work style", onTap: { showWorkStyleEditor = true })

            Divider().background(Color.gray.opacity(0.1))

            NavigationLink(destination: HomeBaseEditorView(homeBase: $homeBase)) {
                ProfileEditRow(title: "Home Base", value: homeBase.isEmpty ? "Add home base" : homeBase)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { hideTabBar() })

            Divider().background(Color.gray.opacity(0.1))

            morningPersonRow
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var morningPersonRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Morning Person")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(charcoalColor)
                Text(morningPerson == nil ? "Not set" : (morningPerson! ? "Yes" : "No"))
                    .font(.system(size: 14))
                    .foregroundColor(morningPerson == nil ? charcoalColor.opacity(0.4) : charcoalColor.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 8) {
                Button { morningPerson = true } label: {
                    Text("Yes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(morningPerson == true ? .white : charcoalColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(morningPerson == true ? burntOrange : desertSand)
                        .clipShape(Capsule())
                }

                Button { morningPerson = false } label: {
                    Text("No")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(morningPerson == false ? .white : charcoalColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(morningPerson == false ? burntOrange : desertSand)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Interests Section

    var interestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoalColor.opacity(0.6))

            if interests.isEmpty {
                Button(action: { showInterestEditor = true }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Interest")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.gray.opacity(0.3))
                    )
                }
            } else {
                FlowLayout(data: interests.map { EditProfileInterestItem($0) }, spacing: 8) { item in
                    ProfileInterestTag(interest: item.name)
                }

                Button(action: { showInterestEditor = true }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Interest")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(charcoalColor.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.gray.opacity(0.3))
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(charcoalColor.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private func hideTabBar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tabBarVisibility.isVisible = false
        }
    }
}
